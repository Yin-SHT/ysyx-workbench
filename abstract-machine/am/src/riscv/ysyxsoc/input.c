#include <am.h>
#include <ysyxsoc.h>

#define PS2KBD_ADDR   0x10011000

#define PS2_ESCAPE        0x76                
#define PS2_F1            0x05            
#define PS2_F2            0x06            
#define PS2_F3            0x04            
#define PS2_F4            0x0c            
#define PS2_F5            0x03            
#define PS2_F6            0x0b            
#define PS2_F7            0x83            
#define PS2_F8            0x0a            
#define PS2_F9            0x01            
#define PS2_F10           0x09            
#define PS2_F11           0x78            
#define PS2_F12           0x07            
#define PS2_GRAVE         0x0e              
#define PS2_1             0x16          
#define PS2_2             0x1e          
#define PS2_3             0x26          
#define PS2_4             0x25          
#define PS2_5             0x2e          
#define PS2_6             0x36          
#define PS2_7             0x3d          
#define PS2_8             0x3e          
#define PS2_9             0x46          
#define PS2_0             0x45          
#define PS2_MINUS         0x4e              
#define PS2_EQUALS        0x55                
#define PS2_BACKSPACE     0x66                  
#define PS2_TAB           0x0d            
#define PS2_Q             0x15          
#define PS2_W             0x1d          
#define PS2_E             0x24          
#define PS2_R             0x2d          
#define PS2_T             0x2c          
#define PS2_Y             0x35          
#define PS2_U             0x3c          
#define PS2_I             0x43          
#define PS2_O             0x44          
#define PS2_P             0x4d          
#define PS2_LEFTBRACKET   0x54                    
#define PS2_RIGHTBRACKET  0x5b                      
#define PS2_BACKSLASH     0x5d                  
#define PS2_CAPSLOCK      0x58                  
#define PS2_A             0x1c          
#define PS2_S             0x1b          
#define PS2_D             0x23          
#define PS2_F             0x2b          
#define PS2_G             0x34          
#define PS2_H             0x33          
#define PS2_J             0x3b          
#define PS2_K             0x42          
#define PS2_L             0x4b          
#define PS2_SEMICOLON     0x4c                  
#define PS2_APOSTROPHE    0x52                    
#define PS2_RETURN        0x5a                
#define PS2_LSHIFT        0x12                
#define PS2_Z             0x1a          
#define PS2_X             0x22          
#define PS2_C             0x21          
#define PS2_V             0x2a          
#define PS2_B             0x32          
#define PS2_N             0x31          
#define PS2_M             0x3a          
#define PS2_COMMA         0x41              
#define PS2_PERIOD        0x49                
#define PS2_SLASH         0x4a              
#define PS2_RSHIFT        0x59                
#define PS2_LCTRL         0x14              
#define PS2_LALT          0x11              
#define PS2_SPACE         0x29              
#define PS2_RALT          0xe011            
#define PS2_RCTRL         0xe014            
#define PS2_UP            0xe075          
#define PS2_DOWN          0xe072            
#define PS2_LEFT          0xe06b            
#define PS2_RIGHT         0xe074            
#define PS2_INSERT        0xe070              
#define PS2_DELETE        0xe071              
#define PS2_HOME          0xe06c            
#define PS2_END           0xe069          
#define PS2_PAGEUP        0xe07d              
#define PS2_PAGEDOWN      0xe07a                

static uint8_t code0;
static uint8_t code1;
static uint8_t code2;

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint16_t scan_code = 0;

  code0 = inb(PS2KBD_ADDR);

  if (code0 == 0xe0) {
    code1 = inb(PS2KBD_ADDR);
    if (code1 == 0xf0) {
      kbd->keydown = 0;
      code2 = inb(PS2KBD_ADDR);

      scan_code = (0xe0 << 8) | code2;
    } else {
      kbd->keydown = 1;

      scan_code = (0xe0 << 8) | code1;
    }
  } else if (code0 == 0xf0) {
    code1 = inb(PS2KBD_ADDR);
    kbd->keydown = 0;

    scan_code = code1;
  } else {
    kbd->keydown = 1;

    scan_code = code0;
  }

  switch (scan_code) {
    case PS2_ESCAPE      :  kbd->keycode = AM_KEY_ESCAPE      ;  break;                   
    case PS2_F1          :  kbd->keycode = AM_KEY_F1          ;  break;         
    case PS2_F2          :  kbd->keycode = AM_KEY_F2          ;  break;         
    case PS2_F3          :  kbd->keycode = AM_KEY_F3          ;  break;         
    case PS2_F4          :  kbd->keycode = AM_KEY_F4          ;  break;         
    case PS2_F5          :  kbd->keycode = AM_KEY_F5          ;  break;         
    case PS2_F6          :  kbd->keycode = AM_KEY_F6          ;  break;         
    case PS2_F7          :  kbd->keycode = AM_KEY_F7          ;  break;         
    case PS2_F8          :  kbd->keycode = AM_KEY_F8          ;  break;         
    case PS2_F9          :  kbd->keycode = AM_KEY_F9          ;  break;         
    case PS2_F10         :  kbd->keycode = AM_KEY_F10         ;  break;         
    case PS2_F11         :  kbd->keycode = AM_KEY_F11         ;  break;         
    case PS2_F12         :  kbd->keycode = AM_KEY_F12         ;  break;         
    case PS2_GRAVE       :  kbd->keycode = AM_KEY_GRAVE       ;  break;           
    case PS2_1           :  kbd->keycode = AM_KEY_1           ;  break;       
    case PS2_2           :  kbd->keycode = AM_KEY_2           ;  break;       
    case PS2_3           :  kbd->keycode = AM_KEY_3           ;  break;       
    case PS2_4           :  kbd->keycode = AM_KEY_4           ;  break;       
    case PS2_5           :  kbd->keycode = AM_KEY_5           ;  break;       
    case PS2_6           :  kbd->keycode = AM_KEY_6           ;  break;       
    case PS2_7           :  kbd->keycode = AM_KEY_7           ;  break;       
    case PS2_8           :  kbd->keycode = AM_KEY_8           ;  break;       
    case PS2_9           :  kbd->keycode = AM_KEY_9           ;  break;       
    case PS2_0           :  kbd->keycode = AM_KEY_0           ;  break;       
    case PS2_MINUS       :  kbd->keycode = AM_KEY_MINUS       ;  break;           
    case PS2_EQUALS      :  kbd->keycode = AM_KEY_EQUALS      ;  break;             
    case PS2_BACKSPACE   :  kbd->keycode = AM_KEY_BACKSPACE   ;  break;               
    case PS2_TAB         :  kbd->keycode = AM_KEY_TAB         ;  break;         
    case PS2_Q           :  kbd->keycode = AM_KEY_Q           ;  break;       
    case PS2_W           :  kbd->keycode = AM_KEY_W           ;  break;       
    case PS2_E           :  kbd->keycode = AM_KEY_E           ;  break;       
    case PS2_R           :  kbd->keycode = AM_KEY_R           ;  break;       
    case PS2_T           :  kbd->keycode = AM_KEY_T           ;  break;       
    case PS2_Y           :  kbd->keycode = AM_KEY_Y           ;  break;       
    case PS2_U           :  kbd->keycode = AM_KEY_U           ;  break;       
    case PS2_I           :  kbd->keycode = AM_KEY_I           ;  break;       
    case PS2_O           :  kbd->keycode = AM_KEY_O           ;  break;       
    case PS2_P           :  kbd->keycode = AM_KEY_P           ;  break;       
    case PS2_LEFTBRACKET :  kbd->keycode = AM_KEY_LEFTBRACKET ;  break;                 
    case PS2_RIGHTBRACKET:  kbd->keycode = AM_KEY_RIGHTBRACKET;  break;                   
    case PS2_BACKSLASH   :  kbd->keycode = AM_KEY_BACKSLASH   ;  break;               
    case PS2_CAPSLOCK    :  kbd->keycode = AM_KEY_CAPSLOCK    ;  break;               
    case PS2_A           :  kbd->keycode = AM_KEY_A           ;  break;       
    case PS2_S           :  kbd->keycode = AM_KEY_S           ;  break;       
    case PS2_D           :  kbd->keycode = AM_KEY_D           ;  break;       
    case PS2_F           :  kbd->keycode = AM_KEY_F           ;  break;       
    case PS2_G           :  kbd->keycode = AM_KEY_G           ;  break;       
    case PS2_H           :  kbd->keycode = AM_KEY_H           ;  break;       
    case PS2_J           :  kbd->keycode = AM_KEY_J           ;  break;       
    case PS2_K           :  kbd->keycode = AM_KEY_K           ;  break;       
    case PS2_L           :  kbd->keycode = AM_KEY_L           ;  break;       
    case PS2_SEMICOLON   :  kbd->keycode = AM_KEY_SEMICOLON   ;  break;               
    case PS2_APOSTROPHE  :  kbd->keycode = AM_KEY_APOSTROPHE  ;  break;                 
    case PS2_RETURN      :  kbd->keycode = AM_KEY_RETURN      ;  break;             
    case PS2_LSHIFT      :  kbd->keycode = AM_KEY_LSHIFT      ;  break;             
    case PS2_Z           :  kbd->keycode = AM_KEY_Z           ;  break;       
    case PS2_X           :  kbd->keycode = AM_KEY_X           ;  break;       
    case PS2_C           :  kbd->keycode = AM_KEY_C           ;  break;       
    case PS2_V           :  kbd->keycode = AM_KEY_V           ;  break;       
    case PS2_B           :  kbd->keycode = AM_KEY_B           ;  break;       
    case PS2_N           :  kbd->keycode = AM_KEY_N           ;  break;       
    case PS2_M           :  kbd->keycode = AM_KEY_M           ;  break;       
    case PS2_COMMA       :  kbd->keycode = AM_KEY_COMMA       ;  break;           
    case PS2_PERIOD      :  kbd->keycode = AM_KEY_PERIOD      ;  break;             
    case PS2_SLASH       :  kbd->keycode = AM_KEY_SLASH       ;  break;           
    case PS2_RSHIFT      :  kbd->keycode = AM_KEY_RSHIFT      ;  break;             
    case PS2_LCTRL       :  kbd->keycode = AM_KEY_LCTRL       ;  break;           
    case PS2_LALT        :  kbd->keycode = AM_KEY_LALT        ;  break;           
    case PS2_SPACE       :  kbd->keycode = AM_KEY_SPACE       ;  break;           
    case PS2_RALT        :  kbd->keycode = AM_KEY_RALT        ;  break;         
    case PS2_RCTRL       :  kbd->keycode = AM_KEY_RCTRL       ;  break;         
    case PS2_UP          :  kbd->keycode = AM_KEY_UP          ;  break;       
    case PS2_DOWN        :  kbd->keycode = AM_KEY_DOWN        ;  break;         
    case PS2_LEFT        :  kbd->keycode = AM_KEY_LEFT        ;  break;         
    case PS2_RIGHT       :  kbd->keycode = AM_KEY_RIGHT       ;  break;         
    case PS2_INSERT      :  kbd->keycode = AM_KEY_INSERT      ;  break;           
    case PS2_DELETE      :  kbd->keycode = AM_KEY_DELETE      ;  break;           
    case PS2_HOME        :  kbd->keycode = AM_KEY_HOME        ;  break;         
    case PS2_END         :  kbd->keycode = AM_KEY_END         ;  break;       
    case PS2_PAGEUP      :  kbd->keycode = AM_KEY_PAGEUP      ;  break;           
    case PS2_PAGEDOWN    :  kbd->keycode = AM_KEY_PAGEDOWN    ;  break;             
    default: kbd->keycode = AM_KEY_NONE; break;
  }
}