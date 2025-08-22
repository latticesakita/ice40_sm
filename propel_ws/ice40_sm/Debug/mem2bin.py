import argparse
import struct

def convert_to_binary(input_file, output_file, endian='big'):
    with open(input_file, 'r') as infile:
        lines = infile.readlines()

    with open(output_file, 'wb') as outfile:
        for line in lines:
            line = line.strip()
            if not line:
                continue
            # Convert hex string to integer
            value = int(line, 16)
            # Pack integer into 4 bytes according to endianness
            if endian == 'big':
                data = struct.pack('>I', value)
            else:
                data = struct.pack('<I', value)
            outfile.write(data)

def main():
    parser = argparse.ArgumentParser(description="Convert hex text to binary")
    parser.add_argument("input_file", help="Path to input text file")
    parser.add_argument("output_file", help="Path to output binary file")
    parser.add_argument("-be", action="store_true", help="Use big endian format")
    parser.add_argument("-le", action="store_true", help="Use little endian format")
    args = parser.parse_args()

    if args.be and args.le:
        print("Choose either -be or -le, not both.")
        return

    endian = 'big' if args.be else 'little'
    convert_to_binary(args.input_file, args.output_file, endian)

if __name__ == "__main__":
    main()
