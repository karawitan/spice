/* -*- Mode: C; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/*
   Copyright (C) 2020 Red Hat, Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, see <http://www.gnu.org/licenses/>.
*/
#pragma once

#include <spice/macros.h>
#include <spice/vd_agent.h>

SPICE_BEGIN_DECLS

#include <spice/start-packed.h>

/* This helper macro is to define a structure in a way compatible with
 * Microsoft compiler */
#define SPICE_INNER_FIELD_STATUS_ERROR(type, name) \
    struct SPICE_ATTR_PACKED { \
        char common_ ## name[sizeof(VDAgentFileXferStatusMessage)]; \
        type name; \
    }

/**
 * Structure to fill with transfer status.
 * Fill as much details as you can and call agent_prepare_filexfer_status
 * before sending to adjust for capabilities and endianness.
 * If any detail are filled the status_size passed to agent_prepare_filexfer_status
 * should be updated.
 */
typedef union SPICE_ATTR_PACKED AgentFileXferStatusMessageFull {
    VDAgentFileXferStatusMessage common;
    SPICE_INNER_FIELD_STATUS_ERROR(VDAgentFileXferStatusNotEnoughSpace, not_enough_space);
    SPICE_INNER_FIELD_STATUS_ERROR(VDAgentFileXferStatusError, error);
} AgentFileXferStatusMessageFull;

#undef SPICE_INNER_FIELD_STATUS_ERROR

#include <spice/end-packed.h>

/**
 * Prepare AgentFileXferStatusMessageFull to
 * be sent to network.
 * Avoid protocol incompatibilities and endian issues
 */
void
agent_prepare_filexfer_status(AgentFileXferStatusMessageFull *status, size_t *status_size,
                              const uint32_t *capabilities, uint32_t capabilities_size);

/**
 * Possible results checking a message.
 * Beside AGENT_CHECK_NO_ERROR all other conditions are errors.
 */
typedef enum AgentCheckResult {
    AGENT_CHECK_NO_ERROR,
    AGENT_CHECK_WRONG_PROTOCOL_VERSION,
    AGENT_CHECK_UNKNOWN_MESSAGE,
    AGENT_CHECK_INVALID_SIZE,
    AGENT_CHECK_TRUNCATED,
    AGENT_CHECK_INVALID_DATA,
} AgentCheckResult;

/**
 * Check message from network and fix endianness
 * Returns AGENT_CHECK_NO_ERROR if message is valid.
 * message buffer size should be message_header->size.
 */
AgentCheckResult
agent_check_message(const VDAgentMessage *message_header, uint8_t *message,
                    const uint32_t *capabilities, uint32_t capabilities_size);

SPICE_END_DECLS
