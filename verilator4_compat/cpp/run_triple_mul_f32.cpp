#include "VTripleMulPipe_l4_f32.h"
#include "run_three_op_vectors.h"

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    if (argc < 2) {
        std::cerr << "usage: " << argv[0] << " <vector-file>" << std::endl;
        return 2;
    }
    VTripleMulPipe_l4_f32 top;
    return run_three_op_vectors(&top, argv[1], 33, "TripleMulPipe_l4_f32");
}
