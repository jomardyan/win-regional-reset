#!/usr/bin/env python3
"""
Quick launcher for Windows Regional Settings Reset - Python Edition

This launcher provides a simple way to start the application with
different modes and configurations.
"""

import sys
import os
import subprocess

def main():
    """Main launcher function"""
    script_path = os.path.join(os.path.dirname(__file__), 'regional_settings_reset.py')
    
    print("Windows Regional Settings Reset - Python Edition v2.0")
    print("=" * 55)
    print()
    print("Launch Options:")
    print("1. Interactive Menu (Recommended)")
    print("2. Quick Reset (pl-PL)")
    print("3. Command Line Mode")
    print("4. Help & Usage")
    print("5. Exit")
    print()
    
    try:
        choice = input("Select option (1-5): ").strip()
        
        if choice == '1':
            # Interactive menu
            subprocess.run([sys.executable, script_path, '--menu'])
        elif choice == '2':
            # Quick reset
            subprocess.run([sys.executable, script_path, '--locale', 'pl-PL'])
        elif choice == '3':
            # Command line mode
            locale = input("Enter locale (e.g., en-US): ").strip()
            if locale:
                args = [sys.executable, script_path, '--locale', locale]
                force = input("Force mode? (y/N): ").strip().lower()
                if force == 'y':
                    args.append('--force')
                subprocess.run(args)
            else:
                print("No locale specified.")
        elif choice == '4':
            # Help
            subprocess.run([sys.executable, script_path, '--help'])
        elif choice == '5':
            # Exit
            print("Goodbye!")
            return
        else:
            print("Invalid choice.")
            
    except KeyboardInterrupt:
        print("\nOperation cancelled.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()