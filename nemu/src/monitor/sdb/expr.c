/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include "memory/paddr.h" // for paddr_read()

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>


enum {
  TK_NOTYPE = 256, 
  TK_UNSIGNED,
  TK_PC,
  TK_REG,
  TK_HEX,
  TK_DIGIT, 
  TK_LBCT, TK_RBCT,
  TK_MUL, TK_DIV, TK_PLUS, TK_SUB,
  TK_NEQ, TK_EQ, TK_AND,
  
  // Unary operator
  TK_NEG, TK_DEREF,
  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},                // spaces
  {"\\(unsigned\\)", TK_UNSIGNED},  // unsigned
  {"\\$pc", TK_PC},                 // pc
  {"\\$0", TK_REG},                 // reg
  {"\\$[tagsr][ap0-9]+", TK_REG},   // reg
  {"0[xX][0-9a-fA-F]+", TK_HEX},    // hex
  {"[0-9]+", TK_DIGIT},             // digit

  {"\\(", TK_LBCT},                 // left bracket
  {"\\)", TK_RBCT},                 // right bracket

  {"/", TK_DIV},                    // div
  {"\\*", TK_MUL},                  // mul
  
  {"\\+", TK_PLUS},                 // plus
  {"-", TK_SUB},                    // sub
  
  {"!=", TK_NEQ},                   // not equal
  {"==", TK_EQ},                    // equal
  {"&&", TK_AND},                   // and

};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

#define TOKEN_STR_SIZE 32

typedef struct token {
  int type;
  char str[TOKEN_STR_SIZE];
} Token;

#define TOKENS_SIZE 1024

static Token tokens[TOKENS_SIZE] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;
        if (substr_len > TOKEN_STR_SIZE - 1) {
          RED_PRINT("TOKEN POS: %d SIZE: %d\n---TOO LARGE, TRY AGAIN\n", position, substr_len );
          return false;
        }
        
        /*
        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);
        */

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
          case (TK_PC):
          case (TK_REG):
          case (TK_HEX):
          case (TK_DIGIT): {
            strncpy(tokens[nr_token].str, substr_start, substr_len);
            tokens[nr_token].str[substr_len] = '\0';
            tokens[nr_token].type = rules[i].token_type;
            break;
          }
          case (TK_LBCT):   strcpy(tokens[nr_token].str, "(");  tokens[nr_token].type = TK_LBCT;   break;
          case (TK_RBCT):   strcpy(tokens[nr_token].str, ")");  tokens[nr_token].type = TK_RBCT;   break;
          case (TK_DIV):    strcpy(tokens[nr_token].str, "/");  tokens[nr_token].type = TK_DIV;    break;
          case (TK_MUL):    strcpy(tokens[nr_token].str, "*");  tokens[nr_token].type = TK_MUL;    break;
          case (TK_SUB):    strcpy(tokens[nr_token].str, "-");  tokens[nr_token].type = TK_SUB;    break;
          case (TK_PLUS):   strcpy(tokens[nr_token].str, "+");  tokens[nr_token].type = TK_PLUS;   break;
          case (TK_NEQ):    strcpy(tokens[nr_token].str, "!=");  tokens[nr_token].type = TK_NEQ;   break;
          case (TK_EQ):     strcpy(tokens[nr_token].str, "==");  tokens[nr_token].type = TK_EQ;    break;
          case (TK_AND):    strcpy(tokens[nr_token].str, "&&");  tokens[nr_token].type = TK_AND;    break;
          case (TK_NOTYPE): break;
          case (TK_UNSIGNED): break;
          default: TODO();
        }

        if (rules[i].token_type != TK_NOTYPE && rules[i].token_type != TK_UNSIGNED ) nr_token++;
        break;
      }
    }

    if (i == NR_REGEX) {
      RED_PRINT("NO MATCH AT POSITION %d\n%s\n%*.s^\n; TRY AGAIN\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

/*
 * Static functions in C are functions that are 
 * restricted to the same file in which they are defined. 
 * The functions in C are by default global. If we want to 
 * limit the scope of the function, we use the keyword static 
 * before the function. Doing so, restricts the scope of the 
 * function in other files, and the function remains callable 
 * only in the file in which it is defined.
*/
static bool check_par_match(int p, int q) {
  int bct_stack[TOKENS_SIZE] __attribute__((unused));
  int top = -1;

  for (int i = p; i <= q; i++) {
    if (tokens[i].type == TK_LBCT) {
      bct_stack[++top] = TK_LBCT;
    } else if (tokens[i].type == TK_RBCT) {
      if (top == -1) {
        // Can't match, RBCT more than LBCT
        RED_PRINT("RBCT more than LBCT, TRY AGAIN\n");
        return false;
      } else {
        top--;
      }
    }
  }
  
  // Can't match, LBCT more than LBCT
  if (top != -1) {
    RED_PRINT("LBCT more than RBCT, TRY AGAIN\n");
    return false;
  }

  // Match, LBCT equal with RBCT
  return true;
}

static bool check_parentheses(int p, int q) {
  if (tokens[p].type != TK_LBCT || tokens[q].type != TK_RBCT) {
    /* The expression is surrounded by a matched pair of parentheses */
    return false;
  }

  int bct_stack[TOKENS_SIZE] __attribute__((unused));
  int top = -1;

  for (int i = p + 1; i < q; i++) {
    if (tokens[i].type == TK_LBCT) {
      bct_stack[++top] = TK_LBCT;
    } else if (tokens[i].type == TK_RBCT) {
      if (top == -1) {
        return false;
      } else {
        top--;
      }
    }
  }
  
  if (top != -1) {
    return false;
  }

  return true;
}

typedef struct operator {
  int idx;
  int type;
  int level;
} Operator;

int master_op(int p, int q) {
  Operator op_stack[TOKENS_SIZE] __attribute__((unused));
  int top = -1;

  for (int i = p; i <= q; i++) {
    switch (tokens[i].type) {
      case (TK_LBCT): top++; op_stack[top].type = TK_LBCT; op_stack[top].idx = i; break; 
      case (TK_RBCT): {
        while (top >= 0 && op_stack[top].type != TK_LBCT) {
          top--;
        }
        if (top != -1) {
          top--;
        }
        break;
      }
      case (TK_NEG):  
      case (TK_DEREF): {
        int level = 2;
        if (top == -1 || op_stack[top].type == TK_LBCT || level >= op_stack[top].level) {
          top++;
          op_stack[top].level = level;
          op_stack[top].type = tokens[i].type;
          op_stack[top].idx = i;
        }
        break;
      }
      case (TK_DIV):  
      case (TK_MUL): {
        int level = 3;
        if (top == -1 || op_stack[top].type == TK_LBCT || level >= op_stack[top].level) {
          top++;
          op_stack[top].level = level;
          op_stack[top].type = tokens[i].type;
          op_stack[top].idx = i;
        }
        break;
      }
      case (TK_SUB):
      case (TK_PLUS): {
        int level = 4;
        if (top == -1 || op_stack[top].type == TK_LBCT || level >= op_stack[top].level) {
          top++;
          op_stack[top].level = level;
          op_stack[top].type = tokens[i].type;
          op_stack[top].idx = i;
        }
        break;
      }
      case (TK_EQ):
      case (TK_NEQ):
      case (TK_AND): {
        int level = 7;
        if (top == -1 || op_stack[top].type == TK_LBCT || level >= op_stack[top].level) {
          top++;
          op_stack[top].level = level;
          op_stack[top].type = tokens[i].type;
          op_stack[top].idx = i;
        }
        break;
      }
      default: break;
    }
  }
  return ( top == -1 ) ? p : op_stack[top].idx;
}

uint32_t eval(int p, int q, bool *success) {
  if (!success) return 0;

  if (p > q) {
    return 0;
  } else if (p == q) {
    assert(tokens[p].type == TK_PC || tokens[p].type == TK_REG || \
      tokens[p].type == TK_HEX || tokens[p].type == TK_DIGIT);

    uint32_t val = 0;

    switch (tokens[p].type) {
      case (TK_PC):     val = cpu.pc; break;
      case (TK_REG):    val = isa_reg_str2val(tokens[p].str, success); break;
      case (TK_HEX):    sscanf(tokens[p].str, "%x", &val); break;
      case (TK_DIGIT):  sscanf(tokens[p].str, "%u", &val); break;
      default: TODO(); 
    }

    if (p != 0 && tokens[p - 1].type == TK_DEREF) {
      paddr_t addr = val;
      val = paddr_read(addr, 4); // ! 4 or 1 ?
    }

    return val;
  } else if (check_parentheses(p, q) == true) {
    return eval(p + 1, q - 1, success);
  } else {
    int idx = master_op(p, q);
    uint32_t val1 = eval(p, idx - 1, success);
    uint32_t val2 = eval(idx + 1, q, success);

    switch (tokens[idx].type) {
      case (TK_DIV): {
        if (val2 == 0) {
          RED_PRINT("Div by zero, TRY AGAIN\n");
          *success = false;
          return 0;
        }
        return val1 / val2;
      }
      case (TK_DEREF):  return val1 + val2;
      case (TK_NEG):    return val1 - val2;
      case (TK_MUL):    return val1 * val2;
      case (TK_PLUS):   return val1 + val2;
      case (TK_SUB):    return val1 - val2;
      case (TK_NEQ):    return val1 != val2;
      case (TK_EQ):     return val1 == val2;
      case (TK_AND):    return val1 && val2;
      default: {
        RED_PRINT("Unsupported operator, TRY AGAIN\n");
        *success = false;
        return 0;
      }
    }
  }
}

word_t expr(char *e, bool *success) {
  if (!make_token(e) || !check_par_match(0, nr_token - 1)) {
    // Expr is incorrect, failed
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  // Process tokens to get the right TK_NEG and TK_DEREF
  for (int i = 0; i < nr_token; i++) {
    int pre_type = ( i == 0 ) ? 0 : tokens[i - 1].type;
    if (tokens[i].type == TK_SUB && (i == 0 || (pre_type != TK_REG && pre_type != TK_HEX \
    && pre_type != TK_DIGIT && pre_type != TK_RBCT))) {
      tokens[i].type = TK_NEG;
    } else if (tokens[i].type == TK_MUL && (i == 0 || (pre_type != TK_REG && pre_type != TK_HEX \
    && pre_type != TK_DIGIT && pre_type != TK_RBCT))) {
      tokens[i].type = TK_DEREF;
    }
  }

  return eval(0, nr_token - 1, success);
}