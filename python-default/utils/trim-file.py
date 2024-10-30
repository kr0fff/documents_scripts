import re
import sys
import pyperclip

def convert_to_single_line(input_file):
    """Преобразует содержимое файла в одну строку.

    Args:
        input_file (str): Путь к входному файлу.
    """

    with open(input_file, 'r') as f:
        single_line_content = f.read().replace('\n', ' ').replace('\t', '').strip()
        single_line_content = re.sub(' +', ' ', single_line_content)
        pyperclip.copy(single_line_content)
        print(f"Текст скопирован в буфер обмена: {single_line_content}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Не указан путь к файлу.")
        sys.exit(1)

    input_file = sys.argv[1]
    convert_to_single_line(input_file)