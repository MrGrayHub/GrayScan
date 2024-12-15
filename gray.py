import shutil
import pyfiglet

def print_large_title(title):
    bold_start = "\033[1m"
    bold_end = "\033[0m"
    green_color = "\033[32m"  
    
    return f"{bold_start}{green_color}{title}{bold_end}"

def printTitle():
    title_text = "⚡︎GrayScan⚡︎"
    
    
    terminal_size = shutil.get_terminal_size((80, 20))
    terminal_width = terminal_size.columns

    
    ascii_art = pyfiglet.figlet_format(title_text)
    
   
    centered_ascii_art = "\n".join(line.center(terminal_width) for line in ascii_art.split("\n"))
    
    print(print_large_title(centered_ascii_art))
    print("https://t.me/cyber_gray".center(terminal_width))
    print("v.1.3".center(terminal_width))
    print("© Copyright 2024 MrGray".center(terminal_width))

printTitle()