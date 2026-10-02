#!/usr/bin/env python3
import subprocess
import time
import os

def run_cmd(cmd):
    res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.stdout.strip()

def get_pid():
    out = run_cmd("pgrep -lf AHKMini | grep MacOS/AHKMini | awk '{print $1}'")
    lines = out.split()
    return int(lines[0]) if lines else None

def sample_metrics(pid, duration=2.0, interval=0.4):
    cpus = []
    rss_list = []
    end_time = time.time() + duration
    while time.time() < end_time:
        out = run_cmd(f"ps -p {pid} -o %cpu,rss | tail -n 1")
        parts = out.split()
        if len(parts) >= 2:
            try:
                cpus.append(float(parts[0]))
                rss_list.append(int(parts[1]) / 1024.0) # MB
            except:
                pass
        time.sleep(interval)
    avg_cpu = sum(cpus) / len(cpus) if cpus else 0.0
    avg_rss = sum(rss_list) / len(rss_list) if rss_list else 0.0
    return avg_cpu, avg_rss

def send_key(key_char):
    # Sends key code or keystroke to AHKMini
    scpt = f'''
    tell application "System Events"
        tell process "AHKMini"
            keystroke "{key_char}"
        end tell
    end tell
    '''
    run_cmd(f"osascript -e '{scpt}'")

def send_keycode(code):
    scpt = f'''
    tell application "System Events"
        tell process "AHKMini"
            key code {code}
        end tell
    end tell
    '''
    run_cmd(f"osascript -e '{scpt}'")

def toggle_menu_item():
    scpt = '''
    tell application "System Events"
        tell process "AHKMini"
            click menu bar item 1 of menu bar 1
        end tell
    end tell
    '''
    run_cmd(f"osascript -e '{scpt}'")

def main():
    print("🔬 Starting Empirical Performance Measurement for AHK Mini...")
    # Kill any existing
    run_cmd("killall AHKMini 2>/dev/null || true")
    time.sleep(0.5)
    
    app_path = os.path.abspath("build/Release/AHKMini.app")
    run_cmd(f"open '{app_path}'")
    time.sleep(1.5)
    
    pid = get_pid()
    if not pid:
        print("❌ Could not get PID for AHKMini")
        return
        
    print(f"✅ AHKMini running at PID: {pid}")
    results = {}
    
    # 1. Hidden / Closed initially
    time.sleep(1.0)
    cpu, rss = sample_metrics(pid, duration=2.5)
    results["1. Completely hidden / closed (initial)"] = (cpu, rss)
    print(f"  [1/13] Hidden/Closed: CPU = {cpu:.1f}%, RSS = {rss:.1f} MB")
    
    # 2. Game Selector Open
    toggle_menu_item()
    time.sleep(0.6)
    cpu, rss = sample_metrics(pid, duration=2.0)
    results["2. Game Selector open"] = (cpu, rss)
    print(f"  [2/13] Game Selector Open: CPU = {cpu:.1f}%, RSS = {rss:.1f} MB")
    
    # Test each of the 8 games
    games = [
        ("3. Runner active", "1"),
        ("4. Space active", "2"),
        ("5. Hop active", "3"),
        ("6. Racer active", "4"),
        ("7. Break active", "5"),
        ("8. Snake active", "6"),
        ("9. Pong active", "7"),
        ("10. Memory active", "8"),
    ]
    
    for label, key in games:
        # If in game, return to selector first
        send_keycode(53) # ESC to return to selector
        time.sleep(0.3)
        send_key(key) # Launch game
        time.sleep(0.5)
        # Send spacebar to ensure run is active
        send_keycode(49)
        time.sleep(0.3)
        cpu, rss = sample_metrics(pid, duration=2.0)
        results[label] = (cpu, rss)
        print(f"  [{label}]: CPU = {cpu:.1f}%, RSS = {rss:.1f} MB")
        
    # 11. Game paused (press ESC or click)
    send_keycode(53) # ESC returns to selector in our HUD, or in game we can test pause
    # Launch runner and pause
    send_key("1")
    time.sleep(0.4)
    # Toggle menu to close panel which pauses game
    toggle_menu_item()
    time.sleep(0.6)
    cpu, rss = sample_metrics(pid, duration=2.0)
    results["11. Game paused / panel closed"] = (cpu, rss)
    print(f"  [11/13] Game paused (panel closed): CPU = {cpu:.1f}%, RSS = {rss:.1f} MB")
    
    # 12. Switch between games
    toggle_menu_item() # Reopen
    time.sleep(0.5)
    send_keycode(53) # ESC to selector
    time.sleep(0.2)
    send_key("3") # Hop
    time.sleep(0.3)
    send_keycode(53) # ESC
    time.sleep(0.2)
    send_key("7") # Pong
    time.sleep(0.4)
    cpu, rss = sample_metrics(pid, duration=2.0)
    results["12. Switch between games (Pong active)"] = (cpu, rss)
    print(f"  [12/13] Switch between games: CPU = {cpu:.1f}%, RSS = {rss:.1f} MB")
    
    # 13. Close game after playing
    toggle_menu_item() # Close panel
    time.sleep(0.8)
    cpu, rss = sample_metrics(pid, duration=3.0)
    results["13. Close game after playing (idle background)"] = (cpu, rss)
    print(f"  [13/13] Close game after playing: CPU = {cpu:.1f}%, RSS = {rss:.1f} MB")
    
    print("\n📊 Summary Table of Measured Metrics:")
    print(f"{'State / Scenario':<42} | {'CPU Usage':<10} | {'Memory (RSS)':<12}")
    print("-" * 70)
    for state, (c, m) in results.items():
        print(f"{state:<42} | {c:>6.1f}%    | {m:>8.1f} MB")

if __name__ == "__main__":
    main()
