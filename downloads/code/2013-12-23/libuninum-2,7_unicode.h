typedef unsigned long	UTF32;	/* at least 32 bits */
typedef unsigned short	UTF16;	/* at least 16 bits */
typedef unsigned short	UCS2;	/* at least 16 bits */
typedef unsigned char	UTF8;	/* 8 bits */
typedef unsigned char	Boolean; /* 0 or 1 */

#define UNI_MAX_ASCII (UTF32)0x0000007F 
#define UNI_MAX_BMP   (UTF32)0x0000FFFF
#define UNI_MAX_UTF16 (UTF32)0x0010FFFF
#define UNI_MAX_UTF32 (UTF32)0x7FFFFFFF
#define UNI_SUR_HIGH_START	(UTF32)0xD800
#define UNI_SUR_HIGH_END	(UTF32)0xDBFF
#define UNI_SUR_LOW_START	(UTF32)0xDC00
#define UNI_SUR_LOW_END		(UTF32)0xDFFF
#define UNI_REPLACEMENT_CHAR (UTF32)0x0000FFFD
#define _UNICODE_POSER
