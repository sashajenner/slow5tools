// Sasha Jenner

#include "fast5lite.h"
#include "slow5.h"

#define USAGE_MSG "Usage: %s [OPTION]... [FAST5_FILE/DIR]...\n"
#define HELP_SMALL_MSG "Try '%s --help' for more information.\n"
#define HELP_LARGE_MSG \
    USAGE_MSG \
    "Convert fast5 file(s) to slow5 or (compressed) blow5.\n" \
    "\n" \
    "OPTIONS:\n" \
    "    -b, --binary\n" \
    "        Convert to blow5, rather than the default slow5.\n" \
    "\n" \
    "    -c, --compress\n" \
    "        Convert to compressed blow5.\n" \
    "\n" \
    "    -d, --max-depth=[NUM]\n" \
    "        Set the maximum depth to search directories for fast5 files.\n" \
    "        NUM must be a non-negative integer.\n" \
    "        Default: No maximum depth.\n" \
    "\n" \
    "        E.g. NUM=1: Read the files within a specified directory but\n" \
    "        not those within subdirectories.\n" \
    "\n" \
    "    -h, --help\n" \
    "        Display this message and exit.\n" \
    "\n" \
    "    -o, --output=[FILE]\n" \
    "        Output slow5 or blow5 contents to FILE.\n" \
    "        Default: Stdout.\n" \

static double init_realtime = 0;
static uint64_t bad_fast5_file = 0;
static uint64_t total_reads = 0;

enum FormatOut {
    OUT_ASCII,
    OUT_BINARY,
    OUT_COMPRESS
};

// adapted from https://stackoverflow.com/questions/4553012/checking-if-a-file-is-a-directory-or-just-a-file 
/*
bool is_dir(const char *path) {
    struct stat path_stat;
    if (stat(path, &path_stat) == -1) {
        ERROR("Stat failed to retrive file information%s", "");
        return false;
    }

    return S_ISDIR(path_stat.st_mode);
}
*/

bool has_fast5_ext(const char *f_path) {
    bool ret = false;

    if (f_path != NULL) {
        size_t f_path_len = strlen(f_path);
        size_t fast5_ext_len = strlen(FAST5_EXTENSION);

        if (f_path_len >= fast5_ext_len && 
                strcmp(f_path + (f_path_len - fast5_ext_len), FAST5_EXTENSION) == 0) {
            ret = true;
        }
    }

    return ret;
}

void write_data(void *arg_f_out, enum FormatOut format_out, const std::string read_id, const fast5_t f5, const char *fast5_path) {

    // Interpret file parameter
    if (format_out == OUT_ASCII) {
        FILE *f_out = (FILE *) arg_f_out;

        fprintf(f_out, "%s\t%ld\t%.1f\t%.1f\t%.1f\t%.1f\t", read_id.c_str(),
                f5.nsample,f5.digitisation, f5.offset, f5.range, f5.sample_rate);

        for (uint64_t j = 0; j < f5.nsample; ++ j) {
            if (j == f5.nsample - 1) {
                fprintf(f_out, "%hu", f5.rawptr[j]);
            } else {
                fprintf(f_out, "%hu,", f5.rawptr[j]);
            }
        }

        fprintf(f_out, "\t%d\t%s\t%s\n",0,".",fast5_path);

    } else if (format_out == OUT_BINARY) {
        FILE *f_out = (FILE *) arg_f_out;

        // write length of string
        size_t read_id_len = read_id.length();
        fwrite(&read_id_len, sizeof read_id_len, 1, f_out); 

        // write string
        const char *read_id_c_str = read_id.c_str();
        fwrite(read_id_c_str, sizeof *read_id_c_str, read_id_len, f_out);

        // write other data
        fwrite(&f5.nsample, sizeof f5.nsample, 1, f_out);
        fwrite(&f5.digitisation, sizeof f5.digitisation, 1, f_out);
        fwrite(&f5.offset, sizeof f5.offset, 1, f_out);
        fwrite(&f5.range, sizeof f5.range, 1, f_out);
        fwrite(&f5.sample_rate, sizeof f5.sample_rate, 1, f_out);

        fwrite(f5.rawptr, sizeof *f5.rawptr, f5.nsample, f_out);

        //todo change to variable
        
        uint64_t num_bases = 0;
        fwrite(&num_bases, sizeof num_bases, 1, f_out);

        const char *sequences = ".";
        size_t sequences_len = strlen(sequences);
        fwrite(&sequences_len, sizeof sequences_len, 1, f_out); 
        fwrite(sequences, sizeof *sequences, sequences_len, f_out);

        size_t fast5_path_len = strlen(fast5_path);
        fwrite(&fast5_path_len, sizeof fast5_path_len, 1, f_out); 
        fwrite(fast5_path, sizeof *fast5_path, fast5_path_len, f_out);
            
    } else if (format_out == OUT_COMPRESS) {
        gzFile f_out = (gzFile) arg_f_out;

        // write length of string
        size_t read_id_len = read_id.length();
        gzfwrite(&read_id_len, sizeof read_id_len, 1, f_out); 

        // write string
        const char *read_id_c_str = read_id.c_str();
        gzfwrite(read_id_c_str, sizeof *read_id_c_str, read_id_len, f_out);

        // write other data
        gzfwrite(&f5.nsample, sizeof f5.nsample, 1, f_out);
        gzfwrite(&f5.digitisation, sizeof f5.digitisation, 1, f_out);
        gzfwrite(&f5.offset, sizeof f5.offset, 1, f_out);
        gzfwrite(&f5.range, sizeof f5.range, 1, f_out);
        gzfwrite(&f5.sample_rate, sizeof f5.sample_rate, 1, f_out);

        gzfwrite(f5.rawptr, sizeof *f5.rawptr, f5.nsample, f_out);

        //todo change to variable
        
        uint64_t num_bases = 0;
        gzfwrite(&num_bases, sizeof num_bases, 1, f_out);

        const char *sequences = ".";
        size_t sequences_len = strlen(sequences);
        gzfwrite(&sequences_len, sizeof sequences_len, 1, f_out); 
        gzfwrite(sequences, sizeof *sequences, sequences_len, f_out);

        size_t fast5_path_len = strlen(fast5_path);
        gzfwrite(&fast5_path_len, sizeof fast5_path_len, 1, f_out); 
        gzfwrite(fast5_path, sizeof *fast5_path, fast5_path_len, f_out);
    }

    free(f5.rawptr);
}

int fast5_to_slow5(const char *fast5_path, void *f_out, enum FormatOut format_out) {

    total_reads++;

    fast5_file_t fast5_file = fast5_open(fast5_path);

    if (fast5_file.hdf5_file >= 0) {

        //TODO: can optimise for performance
        if (fast5_file.is_multi_fast5) {
            std::vector<std::string> read_groups = fast5_get_multi_read_groups(fast5_file);
            std::string prefix = "read_";
            for (size_t group_idx = 0; group_idx < read_groups.size(); ++group_idx) {
                std::string group_name = read_groups[group_idx];

                if (group_name.find(prefix) == 0) {
                    std::string read_id = group_name.substr(prefix.size());
                    fast5_t f5;
                    int32_t ret = fast5_read_multi_fast5(fast5_file, &f5, read_id);

                    if (ret < 0) {
                        WARNING("Fast5 file [%s] is unreadable and will be skipped", fast5_path);
                        bad_fast5_file++;
                        fast5_close(fast5_file);
                        return 0;
                    }

                    write_data(f_out, format_out, read_id, f5, fast5_path);
                }
            }

        } else {
            fast5_t f5;
            int32_t ret=fast5_read_single_fast5(fast5_file, &f5);
            if (ret < 0) {
                WARNING("Fast5 file [%s] is unreadable and will be skipped", fast5_path);
                bad_fast5_file++;
                fast5_close(fast5_file);
                return 0;
            }

            std::string read_id = fast5_get_read_id_single_fast5(fast5_file);
            if (read_id == "") {
                WARNING("Fast5 file [%s] does not have a read ID and will be skipped", fast5_path);
                bad_fast5_file++;
                fast5_close(fast5_file);
                return 0;
            }

            write_data(f_out, format_out, read_id, f5, fast5_path);
        }
    }
    else{
        WARNING("Fast5 file [%s] is unreadable and will be skipped", fast5_path);
        bad_fast5_file++;
        return 0;
    }

    fast5_close(fast5_file);

    return 1;

}

void recurse_dir(const char *f_path, void *f_out, enum FormatOut format_out) {

    DIR *dir;
    struct dirent *ent;

    dir = opendir(f_path);

    if (dir == NULL) {
        if (errno == ENOTDIR) {
            // If it has the fast5 extension
            if (has_fast5_ext(f_path)) {
                // Open FAST5 and convert to SLOW5 into f_out
                fast5_to_slow5(f_path, f_out, format_out);
            }

        } else {
            WARNING("File '%s' failed to open - %s.", 
                    f_path, strerror(errno));
        }

    } else {
        fprintf(stderr, "[%s::%.3f*%.2f] Extracting fast5 from %s\n", __func__, 
                realtime() - init_realtime, cputime() / (realtime() - init_realtime), f_path);

        // Iterate through sub files
        while ((ent = readdir(dir)) != NULL) {
            if (strcmp(ent->d_name, ".") != 0 && 
                    strcmp(ent->d_name, "..") != 0) {

                // Make sub path string
                // f_path + '/' + ent->d_name + '\0'
                size_t sub_f_path_len = strlen(f_path) + 1 + strlen(ent->d_name) + 1;
                char *sub_f_path = (char *) malloc(sizeof *sub_f_path * sub_f_path_len);
                MALLOC_CHK(sub_f_path);
                snprintf(sub_f_path, sub_f_path_len, "%s/%s", f_path, ent->d_name);

                // Recurse
                recurse_dir(sub_f_path, f_out, format_out);

                free(sub_f_path);
                sub_f_path = NULL;
            }
        }

        closedir(dir);
    }
}

int f2s_main(int argc, char **argv, struct program_meta *meta) {

    init_realtime = realtime();

    // Debug: print arguments
    if (meta != NULL && meta->debug) {
        if (meta->verbose) {
            VERBOSE("printing the arguments given%s","");
        }

        fprintf(stderr, DEBUG_PREFIX "argv=[",
                __FILE__, __func__, __LINE__);
        for (int i = 0; i < argc; ++ i) {
            fprintf(stderr, "\"%s\"", argv[i]);
            if (i == argc - 1) {
                fprintf(stderr, "]");
            } else {
                fprintf(stderr, ", ");
            }
        }
        fprintf(stderr, NO_COLOUR);
    }

    // No arguments given
    if (argc <= 1) {
        fprintf(stderr, HELP_LARGE_MSG, argv[0]);
        EXIT_MSG(EXIT_FAILURE, argv, meta);
        return EXIT_FAILURE;
    }

    static struct option long_opts[] = {
        {"binary", no_argument, NULL, 'b' },
        {"compress", no_argument, NULL, 'c' },
        {"max-depth", required_argument, NULL, 'd' },
        {"help", no_argument, NULL, 'h' },
        {"output", required_argument, NULL, 'o' },
        {NULL, 0, NULL, 0 }
    };

    // Default options
    long max_depth = -1;
    void *f_out = stdout;
    enum FormatOut format_out = OUT_ASCII;

    // Input arguments
    char *arg_max_depth = NULL;
    char *arg_fname_out = NULL;

    char opt;
    // Parse options
    while ((opt = getopt_long(argc, argv, "bcd:ho:", long_opts, NULL)) != -1) {

        if (meta->debug) {
            DEBUG("opt='%c', optarg=\"%s\", optind=%d, opterr=%d, optopt='%c'",
                  opt, optarg, optind, opterr, optopt);
        }

        switch (opt) {
            case 'b':
                format_out = OUT_BINARY;
                break;
            case 'c':
                format_out = OUT_COMPRESS;
                f_out = gzdopen(STDOUT_FILENO, "w");
                break;
            case 'd':
                arg_max_depth = optarg;
                break;
            case 'h':
                if (meta->verbose) {
                    VERBOSE("displaying large help message%s","");
                }
                fprintf(stdout, HELP_LARGE_MSG, argv[0]);

                EXIT_MSG(EXIT_SUCCESS, argv, meta);
                return EXIT_SUCCESS;
            case 'o':
                arg_fname_out = optarg; 
                break; 
            default: // case '?' 
                fprintf(stderr, HELP_SMALL_MSG, argv[0]);
                EXIT_MSG(EXIT_FAILURE, argv, meta);
                return EXIT_FAILURE;
        }
    }

    // Parse maximum depth argument
    if (arg_max_depth != NULL) {

        if (meta != NULL && meta->verbose) {
            VERBOSE("parsing maximum depth%s","");
        }

        // Check it is a number
        
        // Cannot be empty 
        size_t arg_len = strlen(arg_max_depth);
        if (arg_len == 0) {
            MESSAGE(stderr, "invalid max depth -- '%s'", arg_max_depth);
            fprintf(stderr, HELP_SMALL_MSG, argv[0]);

            EXIT_MSG(EXIT_FAILURE, argv, meta);
            return EXIT_FAILURE;
        }

        for (size_t i = 0; i < arg_len; ++ i) {
            // Not a digit and first char is not a '+'
            if (!isdigit((unsigned char) arg_max_depth[i]) && 
                    !(i == 0 && arg_max_depth[i] == '+')) {
                MESSAGE(stderr, "invalid max depth -- '%s'", arg_max_depth);
                fprintf(stderr, HELP_SMALL_MSG, argv[0]);

                EXIT_MSG(EXIT_FAILURE, argv, meta);
                return EXIT_FAILURE;
            }
        }

        // Parse argument
        max_depth = strtol(arg_max_depth, NULL, 10);
        // Check for overflow
        if (errno == ERANGE) {
            WARNING("Overflow of max depth '%s'. Setting to %ld instead.", 
                    arg_max_depth, max_depth);
        }
    }

    // Parse output argument
    if (arg_fname_out != NULL) { 

        if (meta != NULL && meta->verbose) {
            VERBOSE("parsing output filename%s","");
        }

        // Create new file or
        // Truncate existing file
        void *new_file;
        if (format_out != OUT_COMPRESS) {
            new_file = fopen(arg_fname_out, "w");
        } else {
            new_file = gzopen(arg_fname_out, "w");
        }

        // An error occured
        if (new_file == NULL) {
            ERROR("File '%s' could not be opened - %s.", 
                  arg_fname_out, strerror(errno));

            EXIT_MSG(EXIT_FAILURE, argv, meta);
            return EXIT_FAILURE;
            
        } else {
            f_out = new_file;
        }
    }

    // Check for remaining files to parse
    if (optind >= argc) {
        MESSAGE(stderr, "missing fast5 files or directories%s", "");
        fprintf(stderr, HELP_SMALL_MSG, argv[0]);
        
        EXIT_MSG(EXIT_FAILURE, argv, meta);
        return EXIT_FAILURE;
    }


    // Do the converting
    switch (format_out) {
        case OUT_ASCII:
            fprintf((FILE *) f_out, SLOW5_FILE_FORMAT);
            fprintf((FILE *) f_out, SLOW5_HEADER);
            break;
        case OUT_BINARY:
            fprintf((FILE *) f_out, BLOW5_FILE_FORMAT);
            fprintf((FILE *) f_out, SLOW5_HEADER);
            break;
        case OUT_COMPRESS:
            gzprintf((gzFile) f_out, BLOW5_FILE_FORMAT);
            gzprintf((gzFile) f_out, SLOW5_HEADER);
    }

    for (int i = optind; i < argc; ++ i) {
        // Recursive way
        recurse_dir(argv[i], f_out, format_out);

        // TODO iterative way
    }

    MESSAGE(stderr, "total reads: %lu, bad fast5: %lu",
            total_reads, bad_fast5_file);

    // Close output file 
    if (format_out != OUT_COMPRESS) {
        if (arg_fname_out != NULL && fclose((FILE *) f_out) == EOF) {
            ERROR("File '%s' failed on closing - %s.",
                  arg_fname_out, strerror(errno));

            EXIT_MSG(EXIT_FAILURE, argv, meta);
            return EXIT_FAILURE;
        } 
    } else if (gzclose_w((gzFile) f_out) != Z_OK) {
        ERROR("File '%s' failed on closing - %s.",
              arg_fname_out, strerror(errno));

        EXIT_MSG(EXIT_FAILURE, argv, meta);
        return EXIT_FAILURE;
    }

    EXIT_MSG(EXIT_SUCCESS, argv, meta);
    return EXIT_SUCCESS;
}
