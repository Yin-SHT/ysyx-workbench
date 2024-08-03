#ifndef __PERF_H__
#define __PERF_H__

#include "VysyxSoCFull.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull___024root.h"

void examine_inst();
void getScope();

extern VysyxSoCFull *top;
extern VerilatedVcdC* tfp;
extern VerilatedContext* ctxp;

#endif