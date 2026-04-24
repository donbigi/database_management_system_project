import os
import subprocess
import sys
import numpy as np
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import LinearRegression

SCRIPTS_DIR = os.path.dirname(os.path.realpath(__file__))
APPLY_CONFIG = os.path.join(SCRIPTS_DIR, "../baseline/apply_config.py")
RUN_ITER = os.path.join(SCRIPTS_DIR, "run_al_iteration.sh")

def generate_options(T, Mb, output_path):
    subprocess.run([
        "python3", APPLY_CONFIG,
        "--output", output_path,
        "--memtable_size", str(int(Mb)),
        "--level_multiplier", str(float(T)),
        "--stats"
    ], check=True)

def run_iteration(T, Mb):
    options_file = "/tmp/OPTIONS_AL_TEMP.ini"
    generate_options(T, Mb, options_file)
    result = subprocess.run([
        "bash", RUN_ITER,
        "balanced", options_file
    ], capture_output=True, text=True)
    try:
        # Expected output of run_al_iteration.sh should have latency on the last line
        lines = result.stdout.strip().split('\n')
        # Skip empty lines at the end if any
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

def active_learn_parameter(param_name, fixed_params, search_space, n_initial=3, n_rounds=7):
    X_train = []
    y_train = []
    
    np.random.seed(42)
    initial_samples = np.random.choice(search_space, min(n_initial, len(search_space)), replace=False)
    
    print(f"  [AL Init] Starting with max {n_initial} random samples for {param_name} tuning: {initial_samples}", flush=True)
    for val in initial_samples:
        params = fixed_params.copy()
        params[param_name] = val
        lat = run_iteration(params.get('T', 10), params.get('Mb', 64))
        print(f"    - Sampled {param_name}={val} -> Latency: {lat} µs", flush=True)
        if lat != float('inf') and lat > 0:
            X_train.append([val])
            y_train.append(lat)
            
    for r in range(n_rounds):
        if len(X_train) == 0:
            print("  [AL Error] No valid samples to train on!")
            break
            
        model = LinearRegression()
        poly = PolynomialFeatures(degree=2)
        X_poly = poly.fit_transform(X_train)
        model.fit(X_poly, y_train)
        
        best_pred_lat = float('inf')
        best_val = None
        for val in search_space:
            if [val] not in X_train:
                pred = model.predict(poly.transform([[val]]))[0]
                if pred < best_pred_lat:
                    best_pred_lat = pred
                    best_val = val
                    
        if best_val is None:
            break
            
        print(f"  [AL Round {r+1}/{n_rounds}] Regressor predicts {param_name}={best_val} to be optimal (Pred: {best_pred_lat:.2f} µs). Testing it...", flush=True)
        params = fixed_params.copy()
        params[param_name] = best_val
        lat = run_iteration(params.get('T', 10), params.get('Mb', 64))
        print(f"    - Tested {param_name}={best_val} -> Real Latency: {lat} µs", flush=True)
        if lat != float('inf') and lat > 0:
            X_train.append([best_val])
            y_train.append(lat)
            
    best_idx = np.argmin(y_train)
    return X_train[best_idx][0]

if __name__ == '__main__':
    print("Starting Decoupled Active Tuning...", flush=True)
    
    T_space = list(range(2, 21))
    print("\nStage 1: Tuning Size Ratio (T)...", flush=True)
    best_T = active_learn_parameter('T', {'Mb': 64}, T_space, n_initial=3, n_rounds=5)
    print(f"-> Optimal Size Ratio found: {best_T}", flush=True)
    
    Mb_space = list(range(16, 129, 16))
    print("\nStage 2: Tuning Write Buffer (Mb)...", flush=True)
    best_Mb = active_learn_parameter('Mb', {'T': best_T}, Mb_space, n_initial=3, n_rounds=4)
    print(f"-> Optimal Write Buffer found: {best_Mb}", flush=True)
    
    final_output = sys.argv[1] if len(sys.argv) > 1 else "/opt/rocksdb-workspace/OPTIONS_AL.ini"
    generate_options(best_T, best_Mb, final_output)
    print(f"\nFinal configuration optimized: T={best_T}, Mb={best_Mb}. Saved to {final_output}")
