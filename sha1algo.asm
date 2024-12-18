section .data
    ; Déclaration des constantes SHA1
    h0 dd 0x67452301
    h1 dd 0xEFCDAB89
    h2 dd 0x98BADCFE
    h3 dd 0x10325476
    h4 dd 0xC3D2E1F0
    question db "Entrez votre texte: ", 0x0

section .bss
    ; Déclaration des variables pour le calcul du SHA1
    padded resb 64         ; espace pour le message padding
    words resd 80
    output resd 5           ; espace pour le résultat (40 caractères hex)

    ; String pour stocker le resultat final
    hexString resb 40
    input_message resb 64

section .text
    global _start

_start:
    mov rdi, question
    call print_text

    mov rdi, input_message
    call read_input

    mov rdi, input_message
    call sha1

    mov rax, rdi
    call print_text

    call end_program

end_program:
    mov rax, 60              ; syscall exit
    xor rdi, rdi             ; code de sortie 0
    syscall


print_text:
    ;params (rdi)
    ;returns ()
    call count_text_lenght

    mov rdx, rax    ; lenght buffer
    mov rsi, rdi    ; adresse buffer
    mov rax, 1      ; syscall ID
    mov rdi, 1      ; file descriptor (1 -> stdout)


    syscall
    ret

count_text_lenght:
    ;params (rdi)
    ;returns (rax)
    mov rsi, rdi
    mov rax, 0
    ._loop:
        cmp byte [rsi], 0x0
        je ._end
        inc rsi
        inc rax
        jmp ._loop
    ._end:
    ret

read_input:
    ;params (rdi)
    ;returns (rax)
    
    mov rdx, 100    ; lenght buffer 
    mov rsi, rdi    ; adresse buffer
    mov rax, 0      ; syscall ID
    mov rdi, 0      ; file descriptor (0 -> stdin)

    syscall
    ret



sha1:
    ;params (rdi)
    ;returns (rax)
    push rdi
    call count_text_lenght
    mov rbx, rax
    pop rdi


    xor rcx, rcx
    .copyMessage:
        cmp rcx, rbx
        je .endCopy

        mov al, byte [rdi+rcx]
        mov byte [padded+rcx], al

        inc rcx
        jmp .copyMessage
    .endCopy:

    mov rax, rbx
    ; Ajoute un '1' à la fin du message de base
    mov byte [padded + rax - 1], 0x80


    ; Ajoute sur les 64 dernier bit de padding la représentation de la longueure de l'input en bit
    mov r8, 8
    dec rax
    imul r8
    mov qword [padded+63], rax


    xor rcx, rcx
    .wordsContruct:
        cmp rcx, 16
        je .endWordsConstruct

        mov eax, dword [padded + rcx * 4]
        bswap eax
        mov dword [words + rcx * 4], eax

        inc rcx
        jmp .wordsContruct
    .endWordsConstruct:

    mov rcx, 16
    .extendTo80:
        cmp rcx, 80
        je .endExtend

        xor eax, eax
        mov eax, dword [words + (rcx - 3) * 4]
        xor eax, dword [words + (rcx - 8) * 4]
        xor eax, dword [words + (rcx - 14) * 4]
        xor eax, dword [words + (rcx - 16) * 4]
        rol eax, 1
        mov dword [words + rcx * 4], eax

        inc rcx
        jmp .extendTo80
    .endExtend:


    mov r8d, [h0] ; A
    mov r9d, [h1] ; B
    mov r10d, [h2] ; C
    mov r11d, [h3] ; D
    mov r12d, [h4] ; E

    xor rcx, rcx
    .mainLoop:
        cmp rcx, 80
        je .endMainLoop

        xor eax, eax ; F
        xor ebx, ebx ; K

        cmp rcx, 20
        jl .calc1
        cmp rcx, 40
        jl .calc2
        cmp rcx, 60
        jl .calc3
        jmp .calc4

        .calc1:
            mov eax, r9d
            and eax, r10d
            push rax
            mov eax, r9d
            not eax
            and eax, r11d
            pop rbx
            or eax, ebx
            mov ebx, 0x5A827999
            jmp .suiteCalc

        .calc2:
            mov eax, r9d
            xor eax, r10d
            xor eax, r11d
            mov ebx, 0x6ED9EBA1
            jmp .suiteCalc

        .calc3:
            mov eax, r9d
            and eax, r10d
            push rax
            mov eax, r9d
            and eax, r11d
            push rax
            mov eax, r10d
            and eax, r11d
            pop rbx
            or eax, ebx
            pop rbx
            or eax, ebx
            mov ebx, 0x8F1BBCDC
            jmp .suiteCalc

        .calc4:
            mov eax, r9d
            xor eax, r10d
            xor eax, r11d
            mov ebx, 0xCA62C1D6
            jmp .suiteCalc

        .suiteCalc:
            mov edi, r8d
            rol edi, 5
            add edi, eax
            add edi, r12d
            add edi, ebx
            add edi, dword [words + rcx * 4] ; TEMP VALUE

            mov r12d, r11d
            mov r11d, r10d

            mov esi, r9d
            rol esi, 30
            mov r10d, esi

            mov r9d, r8d
            mov r8d, edi

            inc rcx
            jmp .mainLoop
    .endMainLoop:


    add r8d, dword [h0]
    add r9d, dword [h1]
    add r10d, dword [h2]
    add r11d, dword [h3]
    add r12d, dword [h4]

    bswap r8d
    bswap r9d
    bswap r10d
    bswap r11d
    bswap r12d

    mov dword [output], r8d
    mov dword [output + 4], r9d
    mov dword [output + 8], r10d
    mov dword [output + 12], r11d
    mov dword [output + 16], r12d


    lea rsi, [output]     ; Charger l'adresse de la valeur en mémoire
    lea rdi, [hexString]
    mov rcx, 0              ; Nombre de digits hexadécimaux (4 caractères à afficher)

    convert_loop:

        cmp rcx, 20
        je endConvertLoop

        xor rax, rax
        mov al, [rsi]          ; Charger la valeur actuelle (64 bits)
        and al, 0x0F            ; Extraire le dernier chiffre hexadécimal (4 bits)
        cmp al, 9
        jle is_digitA            ; Si le chiffre est entre 0 et 9
        add al, 'a' - 10       ; Convertir en lettre ('A'-'F')
        repriseA:

        xor rbx, rbx
        mov bl, [rsi]          ; Charger la valeur actuelle (64 bits)
        and bl, 0xF0            ; Extraire le dernier chiffre hexadécimal (4 bits)
        shr bl, 4
        cmp bl, 9
        jle is_digitB            ; Si le chiffre est entre 0 et 9
        add bl, 'a' - 10       ; Convertir en lettre ('A'-'F')
        repriseB:

        mov byte [rdi + rcx * 2], bl
        mov byte [rdi + rcx * 2 + 1], al
        inc rcx
        lea rsi, [output+rcx]
        jmp convert_loop


    is_digitA:
        add al, '0'            ; Convertir en chiffre ('0'-'9')
        jmp repriseA
    is_digitB:
        add bl, '0'            ; Convertir en chiffre ('0'-'9')
        jmp repriseB

    endConvertLoop:

        mov byte [hexString + 40], 0
        lea rax, hexString
        ret
