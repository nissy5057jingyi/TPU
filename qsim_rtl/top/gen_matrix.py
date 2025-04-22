import random

def generate_matrix(filename):
    with open(filename, "w") as f:
        for _ in range(16):
            row = [f"{random.randint(0, 20):3}" for _ in range(16)]
            f.write("".join(row) + "\n")

def transpose_matrix(input_file, output_file):
    matrix = []
    with open(input_file, "r") as f:
        for line in f:
            line = line.rstrip()  # 去除结尾 \n
            row = [int(line[i:i+3]) for i in range(0, len(line), 3) if line[i:i+3].strip()]
            matrix.append(row)

    # Transpose the matrix
    transposed = list(zip(*matrix))

    # Write transposed matrix to output file
    with open(output_file, "w") as f:
        for row in transposed:
            f.write("".join(f"{val:3}" for val in row) + "\n")

# Generate original matrices
generate_matrix("matrixA.txt")
generate_matrix("matrixB_original.txt")

# Transpose matrixB_original.txt into matrixB.txt
transpose_matrix("matrixB_original.txt", "matrixB.txt")



