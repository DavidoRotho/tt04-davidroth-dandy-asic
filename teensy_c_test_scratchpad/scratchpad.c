#include <Arduino.h>

#define START_BYTE 0xAA
#define END_BYTE   0x55

enum DataType {
    X_INSTRUCTIONS = 0x00,
    X_PARAMS_A     = 0x01,
    X_PARAMS_B     = 0x02,
    X_PARAMS_C     = 0x03,
    Y_INSTRUCTIONS = 0x04,
    Y_PARAMS_A     = 0x05,
    Y_PARAMS_B     = 0x06,
    Y_PARAMS_C     = 0x07
};
enum Instructions {
    C_NOP    = 0x00,
    C_LINE   = 0x01,
    C_INCR   = 0x02,
    C_DCRE   = 0x03,
    C_JUMP   = 0x04,
    C_X_RECT = 0x05,
    C_Y_RECT = 0x06,
    C_LINE_D = 0x07
};

void sendPacket(DataType type, uint8_t* data, size_t length) {
    Serial1.write(START_BYTE);
    Serial1.write((uint8_t)type);
    Serial1.write(data, length);
    Serial1.write(END_BYTE);
    delay(0);
}

void setup() {
    Serial1.begin(921600);
    // Your logic here.
    // Serial1.write(30);



}


void loop() {
    uint8_t i = 30;


    bool dir = 0;
        

    while (true)
    {
        uint8_t x_instructions[] = {C_LINE, C_LINE, C_LINE_D, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_LINE, C_LINE, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_LINE};
        uint8_t x_params_a[]     = {100,    80,     120,       39,    i,       30,     130-i,      20, 30,      100,     40+i/4,       39,    5+i,       30,     130-i,      20};
        uint8_t x_params_b[]     = {100,    120,    90+i/4,       90,     i,       30,     130,      200, 50,      100,    40+i/4,       90,     5+i,       30,     130,      200};
        uint8_t x_params_c[]     = {1,      1,      1,       90,     i,       30,     130,      1,  1,      100,    40+i/4,       90,     5+i,       30,     130,      1};

        uint8_t y_instructions[] = {C_LINE_D, C_LINE, C_LINE, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_LINE, C_LINE, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_LINE};
        uint8_t y_params_a[]     = {200,      30,    20,       50,    i,       30,     130-i, 20, 20,      93,    40+i/4,       50,    5+i,       30,     130-i,      20};
        uint8_t y_params_b[]     = {100,      120,    90+i/4,       90,     i,       30,     130,  200, 50,      93,    40+i/4,       90,     5+i,       30,     130,      200};
        uint8_t y_params_c[]     = {1,        1,      1,       90,     i,       30,     130,   1,  1,      100,    40+i/4,       90,     5+i,       30,     130,      1};

        for (int j = 3; j < 16; j++)
        {
            // x_params_a[j] = 0;
            // x_params_b[j] = 0;
            x_params_c[j] = 1;
            // y_params_a[j] = 0;
            // y_params_b[j] = 0;
            y_params_c[j] = 1;
        }


        sendPacket(X_INSTRUCTIONS, x_instructions, sizeof(x_instructions));
        sendPacket(X_PARAMS_A, x_params_a, sizeof(x_params_a));
        sendPacket(X_PARAMS_B, x_params_b, sizeof(x_params_b));
        sendPacket(X_PARAMS_C, x_params_c, sizeof(x_params_c));

        sendPacket(Y_INSTRUCTIONS, y_instructions, sizeof(y_instructions));
        sendPacket(Y_PARAMS_A, y_params_a, sizeof(y_params_a));
        sendPacket(Y_PARAMS_B, y_params_b, sizeof(y_params_b));
        sendPacket(Y_PARAMS_C, y_params_c, sizeof(y_params_c));
 

        
        delay(30);

        if (i > 128)
            dir = 0;
        else if (i < 30)
            dir = 1;
        if (dir)
            i++;
        else
            i--;

    }
    uint8_t x_instructions[] = {C_LINE, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_LINE};
    uint8_t x_params_a[]     = {30,      120,     90+i/4,       39,    i,       30,     130-i,      20};
    uint8_t x_params_b[]     = {200,      120,    90+i/4,       90,     i,       30,     130,      200};

    uint8_t y_instructions[] = {C_LINE, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_LINE};
    uint8_t y_params_a[]     = {20,      110,    90+i/4,       50,    i,       30,     130-i,      20};
    uint8_t y_params_b[]     = {50,      110,    90+i/4,       90,     i,       30,     130,      200};


    sendPacket(X_INSTRUCTIONS, x_instructions, sizeof(x_instructions));
    sendPacket(X_PARAMS_A, x_params_a, sizeof(x_params_a));
    sendPacket(X_PARAMS_B, x_params_b, sizeof(x_params_b));

    sendPacket(Y_INSTRUCTIONS, y_instructions, sizeof(y_instructions));
    sendPacket(Y_PARAMS_A, y_params_a, sizeof(y_params_a));
    sendPacket(Y_PARAMS_B, y_params_b, sizeof(y_params_b));
    while (false)
    {

        dir = !dir;
    
        if (dir)
            i = 10;
        else
            i = 30;

        uint8_t x_params_a[]     = {30,      120,     90+i/4,       39,    i,       30,     130-i,      20};
        uint8_t x_params_b[]     = {200,      120,    90+i/4,       90,     i,       30,     130,      200};

        uint8_t y_params_a[]     = {20,      110,    90+i/4,       50,    i,       30,     130-i,      20};
        uint8_t y_params_b[]     = {50,      110,    90+i/4,       90,     i,       30,     130,      200};
 
        // sendPacket(X_PARAMS_A, x_params_a, sizeof(x_params_a));
        // sendPacket(X_PARAMS_B, x_params_b, sizeof(x_params_b));


        // sendPacket(Y_PARAMS_A, y_params_a, sizeof(y_params_a));
        // sendPacket(Y_PARAMS_B, y_params_b, sizeof(y_params_b));

    }
}
