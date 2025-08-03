/*
   Copyright (C) 2009-2010 Red Hat, Inc.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

       * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above copyright
         notice, this list of conditions and the following disclaimer in
         the documentation and/or other materials provided with the
         distribution.
       * Neither the name of the copyright holder nor the names of its
         contributors may be used to endorse or promote products derived
         from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS
   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
   PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef H_SPICE_COMMON_MESSAGES
#define H_SPICE_COMMON_MESSAGES

#include <spice/protocol.h>
#include <spice/macros.h>

#ifdef USE_SMARTCARD
#include <libcacard.h>
#endif

#include "draw.h"

SPICE_BEGIN_DECLS

typedef struct SpiceMsgCompressedData {
    uint8_t type;
    uint32_t uncompressed_size;
    uint32_t compressed_size;
    uint8_t *compressed_data;
} SpiceMsgCompressedData;

#define SPICE_AGENT_MAX_DATA_SIZE 2048

#ifdef USE_SMARTCARD
typedef struct SpiceMsgSmartcard {
    VSCMsgType type;
    uint32_t length;
    uint32_t reader_id;
    uint8_t data[0];
} SpiceMsgSmartcard;
#endif

#include <common/generated_messages.h>

typedef SpiceMsgMainAgentTokens SpiceMsgcMainAgentTokens;
typedef SpiceMsgMainAgentTokens SpiceMsgcMainAgentStart;
typedef SpiceMsgDisplayDrawCopy SpiceMsgDisplayDrawBlend;
typedef SpiceMsgPlaybackMode SpiceMsgcRecordMode;
typedef SpiceMsgPlaybackPacket SpiceMsgcRecordPacket;

SPICE_END_DECLS

#endif // H_SPICE_COMMON_MESSAGES
