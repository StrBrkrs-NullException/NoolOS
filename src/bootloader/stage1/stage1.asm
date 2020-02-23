bits 16
org 0x7c00  
jmp short Main
nop
times 3-($-$$) dd 0
OEMLabel               db "SOAREOS "
BytesPerSector         dw 512d        
SectorsPerCluster      db 1             
ReservedSectors        dw 1             ;dw 4  WILL NOT WORK! THERE WILL NOT BE ENOUGH SPACE FOR 224 ROOT ENTRIES!
FATCount               db 2             ;number of FATs
RootDirEntryCount      dw 224           ;ammount of maximum root directory entries
TotalSectors           dw 2880          
MediaType              db 0xF0          ;media descriptor byte
SectorsPerFAT          dw 9             
SectorsPerTrack        dw 18             
HeadCount              dw 2             ;number of r/w heads
HiddenSectorCount      dd 0             ;number of hidden sectors
LargeSectorCount       dd 0             ;number of sectors larger then 32 MB
BootDriveNum           db 0             ;drive which holds the boot sector
Reserved               db 0
Signature              db 0x29         ;drive signature, 41d = floppy
SerialNumber           dd 0xDEADBEEF   ;disk serial, little endian for DEADBEEF
VolumeLabel            db "SOAREOS    "
FileSystem             db "FAT12   "    


Main:
;print welcome message
mov ax, 2
int 10h
mov si, msg
call Print
;reset floppy drive

ResetFloppy:
clc
xor ah, ah
mov dl, BYTE [BootDriveNum]
int 13h
;jc ResetFloppy
mov si, msg2
;pusha
call Print
;popa

;calculate length of root directory in sectors into CX
mov ax, 32
mul WORD [RootDirEntryCount]
div WORD [BytesPerSector]
xor dx, dx
mov cx, ax
;calculate offset of root directory from sector 1 into AX (in LBA)
mov al, [FATCount]
mul WORD [SectorsPerFAT]
add ax, WORD [ReservedSectors]
xor dx, dx
;prepare to read root directory into 7C00:2000
mov bx, 0x2000
mov dl, [BootDriveNum]
call LoadSectors
jc FAILURE
;woo, we read it, now find the file a$$hole
mov cx, WORD [RootDirEntryCount]
mov di, 0x2000
NameCompare:
    push cx
    mov cx, 11
    mov si, filename
    push di
    rep cmpsb
    pop di
    je MatchFound
    pop cx
    add di, 32
    loop NameCompare
    jmp FAILURE

MatchFound:
    mov dx, [di + 0x1A]
    mov [cluster], dx
    mov si, msg3
    call Print

;ok we found the file and stored the starting cluster number in DX
;let's find it in the FAT
;first get the size of the FATs and store it in CX
xor ax, ax
mov al, [FATCount]
mul WORD [SectorsPerFAT]
mov cx, ax
xor dx, dx
;make it skip over all reserved sectors, including the bootsector
;and load the FATs into the same buffer as before
mov ax, [ReservedSectors]
mov [diskdataaddress], ax
mov bx, 0x2000
call LoadSectors
;load the clusters and shit
;this is an absolute horribly doccumented nightmare,
;prepare registers to load SoareLDR
;at this point it's midnight and i want to get this over with so i'm effectively just copypasting from brokenthorn
mov ax, 0x00100
mov es, ax
xor bx, bx
mov ax, [cluster]


;ok we loaded it using fairy powder
;note to self: AVOID FAT12, USE FAT16
;now we will pull an "it was all a subroutine"

;through the loop we go!
loadclusters:
    ;load the cluster into the destination buffer
    call LoadCluster 

    ;increment the buffer index by the ammount of bytes a cluster allocates (sectors per cluster * 512)
    push dx
    xor ax, ax
    mov al, [SectorsPerCluster]
    mov dx, 512
    mul dx
    pop dx

    add bx, ax
    ;check if cluster is eof, if yes, don't continue
    mov ax, [cluster]
    mov di, ax
    shr ax, 1
    add di, ax
    add di, 0x2000
    mov ax, [cs:di]
    ;adjust for 12 bits, so check if the cluster is odd or even and mask appropriately
    mov cx, [cluster]
    and cx, 1
    jnz .ODDCLUSTER
    .EVENCLUSTER:
    and ax, 0x0FFF
    jmp .EofCheck
    .ODDCLUSTER:
    shr ax, 4
    .EofCheck: ;actual eof check
    cmp ax, 0x0FF7
    jge postload
    ;compute the next cluster
    mov di, ax
    mov ax, [cs:di]
    mov [cluster], ax
    jmp loadclusters
postload:
;mov si, msg
call Print
push 0x0100
push 0
retf
    
%include 'stage1/disk.asm' 

FAILURE:
    mov si, err
    call Print
    jmp halt

Print:
    lodsb
    or al, al   
    jz .printEnd
    mov ah, 0Eh
    int 10h
    jmp Print
        .printEnd:
        ret



halt: jmp $
msg db "Loading:",0Dh, 0Ah, 0
msg2 db "I:Staging",0Dh,0Ah,0
msg3 db "I:Found SOARELDR",0
err db "F:Hatling",0
filename db "SOARELDRSYS"

diskdataaddress dw 0
claddr dw 0
cluster dw 0

times 510-($-$$) db 0
dw 0xAA55   


