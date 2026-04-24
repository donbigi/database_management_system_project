import os
import subprocess
import sys
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import random

SCRIPTS_DIR = os.path.dirname(os.path.realpath(__file__))
APPLY_CONFIG = os.path.join(SCRIPTS_DIR, "../baseline/apply_config.py")
RUN_ITER = os.path.join(SCRIPTS_DIR, "run_rl_iteration.sh")

# Action bounds
T_MIN, T_MAX = 2.0, 20.0
MB_MIN, MB_MAX = 16.0, 128.0

def generate_options(T, Mb, output_path):
    subprocess.run([
        "python3", APPLY_CONFIG,
        "--output", output_path,
        "--memtable_size", str(int(Mb)),
        "--level_multiplier", str(float(T)),
        "--stats"
    ], check=True)

def run_iteration(T, Mb):
    options_file = "/tmp/OPTIONS_RL_TEMP.ini"
    generate_options(T, Mb, options_file)
    result = subprocess.run([
        "bash", RUN_ITER,
        "balanced", options_file
    ], capture_output=True, text=True)
    try:
        lines = result.stdout.strip().split('\n')
        latency_str = ""
        for line in reversed(lines):
            if bool(line.strip()):
                latency_str = line.strip()
                break
        latency = float(latency_str)
        if latency <= 0:
            return float('inf')
        return latency
    except Exception as e:
        print(f"Failed parsing run output. Except: {e}. Output was: {result.stdout}")
        return float('inf')

class Actor(nn.Module):
    def __init__(self, state_dim, action_dim):
        super(Actor, self).__init__()
        self.fc1 = nn.Linear(state_dim, 64)
        self.fc2 = nn.Linear(64, 64)
        self.out = nn.Linear(64, action_dim)

    def forward(self, state):
        x = torch.relu(self.fc1(state))
        x = torch.relu(self.fc2(x))
        # use tanh so actions are between -1 and 1
        return torch.tanh(self.out(x))

class Critic(nn.Module):
    def __init__(self, state_dim, action_dim):
        super(Critic, self).__init__()
        self.fc1 = nn.Linear(state_dim + action_dim, 64)
        self.fc2 = nn.Linear(64, 64)
        self.out = nn.Linear(64, 1)

    def forward(self, state, action):
        x = torch.cat([state, action], dim=1)
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        return self.out(x)

def unnormalize_action(action):
    # action is [-1, 1]
    T = ((action[0] + 1.0) / 2.0) * (T_MAX - T_MIN) + T_MIN
    Mb = ((action[1] + 1.0) / 2.0) * (MB_MAX - MB_MIN) + MB_MIN
    return np.clip(T, T_MIN, T_MAX), np.clip(Mb, MB_MIN, MB_MAX)

def train_rl(episodes=15):
    state_dim = 3 # (T_norm, Mb_norm, lat_norm)
    action_dim = 2 # (T, Mb)
    
    actor = Actor(state_dim, action_dim)
    critic = Critic(state_dim, action_dim)
    
    actor_opt = optim.Adam(actor.parameters(), lr=1e-3)
    critic_opt = optim.Adam(critic.parameters(), lr=1e-3)
    
    # Initialize state
    T_curr = 10.0
    Mb_curr = 64.0
    lat_curr = run_iteration(T_curr, Mb_curr)
    if lat_curr == float('inf'):
        lat_curr = 100.0  # fallback
    
    T_norm = (T_curr - T_MIN) / (T_MAX - T_MIN) * 2 - 1
    Mb_norm = (Mb_curr - MB_MIN) / (MB_MAX - MB_MIN) * 2 - 1
    lat_norm = np.clip(lat_curr / 100.0, 0, 5) # simple empirical scaling
    
    state = torch.FloatTensor([[T_norm, Mb_norm, lat_norm]])
    
    best_lat = lat_curr
    best_params = (T_curr, Mb_curr)
    
    print(f"  [RL Init] Starting state: T={T_curr}, Mb={Mb_curr}, lat={lat_curr} µs", flush=True)

    gamma = 0.99
    
    for ep in range(episodes):
        # Select action with some exploration noise
        noise = torch.randn(1, 2) * max(0.1, 1.0 - ep/episodes)
        action_val = actor(state).detach() + noise
        action_val = torch.clamp(action_val, -1.0, 1.0)
        
        T_next, Mb_next = unnormalize_action(action_val.numpy()[0])
        T_next = float(T_next)
        Mb_next = float(Mb_next)
        
        print(f"  [RL Ep {ep+1}/{episodes}] Selected Action: T={T_next:.2f}, Mb={Mb_next:.2f}", flush=True)
        lat_next = run_iteration(T_next, Mb_next)
        if lat_next == float('inf'):
            lat_next = 100.0 # penalty equivalent
            
        print(f"    -> Real Latency: {lat_next:.2f} µs", flush=True)
        
        if lat_next < best_lat:
            best_lat = lat_next
            best_params = (T_next, Mb_next)
            
        # Reward: simple inverse of latency. Normalize roughly.
        reward = -lat_next / 100.0 
        
        T_next_norm = (T_next - T_MIN) / (T_MAX - T_MIN) * 2 - 1
        Mb_next_norm = (Mb_next - MB_MIN) / (MB_MAX - MB_MIN) * 2 - 1
        lat_next_norm = np.clip(lat_next / 100.0, 0, 5)
        
        next_state = torch.FloatTensor([[T_next_norm, Mb_next_norm, lat_next_norm]])
        reward_tensor = torch.FloatTensor([[reward]])
        
        # Train Critic
        target_q = reward_tensor + gamma * critic(next_state, actor(next_state).detach())
        current_q = critic(state, action_val)
        critic_loss = nn.MSELoss()(current_q, target_q.detach())
        
        critic_opt.zero_grad()
        critic_loss.backward()
        critic_opt.step()
        
        # Train Actor
        actor_loss = -critic(state, actor(state)).mean()
        actor_opt.zero_grad()
        actor_loss.backward()
        actor_opt.step()
        
        state = next_state
        print(f"    - Updated networks. Critic Loss: {critic_loss.item():.4f}, Actor Loss: {actor_loss.item():.4f}", flush=True)

    return best_params

if __name__ == '__main__':
    print("Starting Deep Deterministic Policy Gradient (DDPG) Tuning...", flush=True)
    
    # Run slightly fewer episodes by default to prevent dragging benchmarking too long
    # Usually real RL requires many more, but for demonstration we run 15
    best_T, best_Mb = train_rl(episodes=15)
    
    print(f"-> Optimal configuration found by RL: T={best_T:.2f}, Mb={best_Mb:.2f}", flush=True)
    
    final_output = sys.argv[1] if len(sys.argv) > 1 else "/opt/rocksdb-workspace/OPTIONS_RL.ini"
    generate_options(best_T, best_Mb, final_output)
    print(f"\nFinal configuration optimized: T={best_T:.2f}, Mb={best_Mb:.2f}. Saved to {final_output}")
