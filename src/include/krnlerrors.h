#ifndef _KRNLERRORS_H
#define _KRNLERRORS_H

typedef enum _KERNELPANIC {
    KERNELPANIC_REACHED_END_OF_KERNEL_CODE  = 0x00000001,
    KERNELPANIC_HAL_FAILURE,                //arg1 = address of failed function
    KERNELPANIC_UNHANDLED_INTERRUPT,
    KERNELPANIC_DEBUG_TRAP                  = 0xDEADBEEF,
}kernelpanic;

typedef enum _STATUSERROR {
    STATUSERROR_SUCCESS                     = 0x00000000,
    STATUSERROR_NOT_ENOUGH_SPACE,
    STATUSERROR_INVALID_PARAMETERS,
    STATUSERROR_NOT_IMPLEMENTED             = 0xFFFFFFFF
}statuserror;
#endif