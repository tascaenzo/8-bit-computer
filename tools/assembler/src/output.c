#include "output.h"

#include <stdio.h>
#include <string.h>

static Cpu8Status build_path(char *buffer, size_t buffer_size, const char *prefix, const char *extension)
{
    int written;

    written = snprintf(buffer, buffer_size, "%s%s", prefix, extension);
    if (written < 0 || (size_t)written >= buffer_size) {
        return CPU8_ERROR_INVALID_ARGUMENT;
    }

    return CPU8_OK;
}

static Cpu8Status write_bin(const char *path, const Cpu8Program *program)
{
    FILE *file = fopen(path, "wb");

    if (file == NULL) {
        return CPU8_ERROR_IO;
    }

    if (program->length > 0 && fwrite(program->bytes, 1, program->length, file) != program->length) {
        fclose(file);
        return CPU8_ERROR_IO;
    }

    fclose(file);
    return CPU8_OK;
}

static Cpu8Status write_hex(const char *path, const Cpu8Program *program)
{
    size_t i;
    FILE *file = fopen(path, "w");

    if (file == NULL) {
        return CPU8_ERROR_IO;
    }

    for (i = 0; i < program->length; i++) {
        if (fprintf(file, "%04zX: %02X\n", i, program->bytes[i]) < 0) {
            fclose(file);
            return CPU8_ERROR_IO;
        }
    }

    fclose(file);
    return CPU8_OK;
}

static Cpu8Status write_header(const char *path, const Cpu8Program *program)
{
    size_t i;
    FILE *file = fopen(path, "w");

    if (file == NULL) {
        return CPU8_ERROR_IO;
    }

    if (fprintf(file, "#ifndef CPU8_PROGRAM_H\n#define CPU8_PROGRAM_H\n\n") < 0 ||
        fprintf(file, "#include <stdint.h>\n\n") < 0 ||
        fprintf(file, "const uint8_t CPU8_PROGRAM[] = {\n") < 0) {
        fclose(file);
        return CPU8_ERROR_IO;
    }

    for (i = 0; i < program->length; i++) {
        if (fprintf(file, "    0x%02X%s", program->bytes[i], i + 1 == program->length ? "" : ",") < 0) {
            fclose(file);
            return CPU8_ERROR_IO;
        }

        if (fprintf(file, "%s", (i + 1) % 8 == 0 || i + 1 == program->length ? "\n" : " ") < 0) {
            fclose(file);
            return CPU8_ERROR_IO;
        }
    }

    if (fprintf(file, "};\n\nconst uint32_t CPU8_PROGRAM_SIZE = %zu;\n\n#endif\n", program->length) < 0) {
        fclose(file);
        return CPU8_ERROR_IO;
    }

    fclose(file);
    return CPU8_OK;
}

Cpu8Status cpu8_write_outputs(const char *output_prefix, const Cpu8Program *program)
{
    char path[512];
    Cpu8Status status;

    if (output_prefix == NULL || program == NULL) {
        return CPU8_ERROR_INVALID_ARGUMENT;
    }

    status = build_path(path, sizeof(path), output_prefix, ".bin");
    if (status != CPU8_OK) {
        return status;
    }
    status = write_bin(path, program);
    if (status != CPU8_OK) {
        return status;
    }

    status = build_path(path, sizeof(path), output_prefix, ".hex");
    if (status != CPU8_OK) {
        return status;
    }
    status = write_hex(path, program);
    if (status != CPU8_OK) {
        return status;
    }

    status = build_path(path, sizeof(path), output_prefix, ".h");
    if (status != CPU8_OK) {
        return status;
    }
    status = write_header(path, program);
    if (status != CPU8_OK) {
        return status;
    }

    return CPU8_OK;
}
