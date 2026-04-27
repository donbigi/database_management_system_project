import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

sns.set_theme(style="whitegrid")
sns.set_palette("Set2")

def main():
    proj_dir = os.path.dirname(os.path.realpath(__file__))
    
    # 1. Throughput Comparison Graph
    data_tp = {
        'Method': ['Baseline', 'Active Learning', 'Reinforcement Learning'] * 3,
        'Workload': ['Write-Heavy']*3 + ['Balanced']*3 + ['Read-Heavy']*3,
        'Throughput (Ops/sec)': [
            17070, 25781, 27600,   # Write
            25432, 23091, 16315,   # Balanced
            21700, 19250, 18850    # Read
        ]
    }
    df_tp = pd.DataFrame(data_tp)
    
    plt.figure(figsize=(10, 6))
    sns.barplot(data=df_tp, x='Workload', y='Throughput (Ops/sec)', hue='Method')
    plt.title('Throughput Comparison Across All Workloads', fontsize=14)
    plt.ylabel('Operations per Second', fontsize=12)
    plt.xlabel('Workload Type', fontsize=12)
    plt.legend(title='Tuning Pipeline')
    plt.tight_layout()
    plt.savefig(os.path.join(proj_dir, 'chart_throughput.png'), dpi=300)
    plt.close()
    
    # 2. P99 Write Latency Graph
    data_p99 = {
        'Method': ['Baseline', 'Active Learning', 'Reinforcement Learning'] * 3,
        'Workload': ['Write-Heavy']*3 + ['Balanced']*3 + ['Read-Heavy']*3,
        'P99 Write Latency (μs)': [
            41.45, 23.62, 29.08,   # Write-Heavy
            33.92, 24.31, 32.71,   # Balanced
            43.94, 30.07, 31.48    # Read-Heavy
        ]
    }
    df_p99 = pd.DataFrame(data_p99)
    
    plt.figure(figsize=(10, 6))
    sns.barplot(data=df_p99, x='Workload', y='P99 Write Latency (μs)', hue='Method')
    plt.title('P99 Tail Write Latency Across All Workloads', fontsize=14)
    plt.ylabel('P99 Latency (Microseconds)', fontsize=12)
    plt.xlabel('Workload Type', fontsize=12)
    plt.legend(title='Tuning Pipeline')
    plt.tight_layout()
    plt.savefig(os.path.join(proj_dir, 'chart_p99_latency.png'), dpi=300)
    plt.close()

    # 3. Write Amplification Graph
    data_amp = {
        'Method': ['Baseline', 'Active Learning', 'Reinforcement Learning'] * 3,
        'Workload': ['Write-Heavy']*3 + ['Balanced']*3 + ['Read-Heavy']*3,
        'Compaction Volume (MB)': [
            761.7, 1291.5, 912.9,   # Write-Heavy
            605.9, 215.6,  31.0,    # Balanced
            642.7, 379.7,  327.6    # Read-Heavy
        ]
    }
    df_amp = pd.DataFrame(data_amp)
    
    plt.figure(figsize=(10, 6))
    sns.barplot(data=df_amp, x='Workload', y='Compaction Volume (MB)', hue='Method')
    plt.title('Internal Write Amplification (SSD Compaction overhead)', fontsize=14)
    plt.ylabel('Compacted Bytes Written to Disk (MB)', fontsize=12)
    plt.xlabel('Workload Type', fontsize=12)
    plt.legend(title='Tuning Pipeline')
    plt.tight_layout()
    plt.savefig(os.path.join(proj_dir, 'chart_write_amp.png'), dpi=300)
    plt.close()

if __name__ == "__main__":
    main()
