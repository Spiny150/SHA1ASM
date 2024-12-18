#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

// Rotation gauche
uint32_t rotate_left(uint32_t value, int shift) {
    return (value << shift) | (value >> (32 - shift));
}

// SHA1 Fonction principale
void sha1(const char* input, char* output) {
    // Initialisation des constantes SHA-1
    uint32_t h0 = 0x67452301;
    uint32_t h1 = 0xEFCDAB89;
    uint32_t h2 = 0x98BADCFE;
    uint32_t h3 = 0x10325476;
    uint32_t h4 = 0xC3D2E1F0;

    // Étape 1 : Prétraitement (Padding)
    size_t input_len = strlen(input);
    size_t padded_len = ((input_len + 8) / 64 + 1) * 64;
    uint8_t* padded = calloc(padded_len, 1);

    memcpy(padded, input, input_len);

    padded[input_len] = 0x80;                       // Ajout d'un bit `1`
    uint64_t bit_len = input_len * 8;               // Taille initiale en bits
    for (int i = 0; i < 8; i++)                     // Ajout de la taille à la fin
        padded[padded_len - 1 - i] = (bit_len >> (i * 8)) & 0xFF;

    // Étape 2 : Découpage en chunks de 512 bits (64 octets)
        
        uint32_t w[80] = {0};
        for (int i = 0; i < 16; i++) {              // Construction des 16 mots initiaux
            w[i] = (padded[i * 4] << 24) |
                   (padded[i * 4 + 1] << 16) |
                   (padded[i * 4 + 2] << 8) |
                   (padded[i * 4 + 3]);
        }

        for (int i = 16; i < 80; i++) {             // Extension à 80 mots
            w[i] = rotate_left(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
        }

        // Étape 3 : Initialisation des variables temporaires
        uint32_t a = h0, b = h1, c = h2, d = h3, e = h4;

        // Étape 4 : Calcul principal
        for (int i = 0; i < 80; i++) {
            uint32_t f = 0, k = 0; 
            if (i < 20) {
                f = (b & c) | ((~b) & d);
                k = 0x5A827999;
            } else if (i < 40) {
                f = b ^ c ^ d;
                k = 0x6ED9EBA1;
            } else if (i < 60) {
                f = (b & c) | (b & d) | (c & d);
                k = 0x8F1BBCDC;
            } else {
                f = b ^ c ^ d;
                k = 0xCA62C1D6;
            }
            uint32_t temp = rotate_left(a, 5) + f + e + k + w[i];
            e = d;
            d = c;
            c = rotate_left(b, 30);
            b = a;
            a = temp;

        }
        printf("A : %x\n", a);
        printf("B : %x\n", b);
        printf("C : %x\n", c);
        printf("D : %x\n", d);
        printf("E : %x\n", e);
        // Mise à jour des variables globales
        h0 += a;
        h1 += b;
        h2 += c;
        h3 += d;
        h4 += e;
    // Libération de la mémoire allouée
    free(padded);

    // Étape 5 : Formater le résultat en hexadécimal
    sprintf(output, "%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4);
}

// Exemple d'utilisation
int main() {
    const char* message = "coucou";
    char hash[41]; // SHA1 produit un hash de 40 caractères + '\0'
    sha1(message, hash);
    printf("SHA1 hash of '%s': %s\n", message, hash);
    return 0;
}
