/*
  Copyright (C) 2018 Red Hat, Inc.

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
/* This file include recorder library headers or if disabled provide
 * replacement declarations */

#ifdef ENABLE_RECORDER
#include <common/recorder/recorder.h>

#elif defined(ENABLE_AGENT_INTERFACE)
#include <common/agent_interface.h>

#else

#include <stdio.h>
#include <stdint.h>
#include <spice/macros.h>

/* Replacement declarations.
 * There declarations should generate no code (beside when no optimization are
 * selected) but catch some possible programming warnings/errors at
 * compile/link time like:
 * - usage of undeclared recorders;
 * - recording formats and arguments;
 * - matching RECORD_TIMING_BEGIN and RECORD_TIMING_END.
 * The only exceptions are tweaks which just generate a variable to hold the
 * value.
 */

typedef struct SpiceEmptyStruct {
    char dummy[0];
} SpiceEmptyStruct;

typedef struct SpiceDummyTweak {
    intptr_t tweak_value;
} SpiceDummyTweak;

#define RECORDER_DECLARE(rec) \
    extern const SpiceEmptyStruct spice_recorder_ ## rec
#define RECORDER(rec, num_rings, comment) \
    RECORDER_DEFINE(rec, num_rings, comment)
#define RECORDER_DEFINE(rec, num_rings, comment) \
    const SpiceEmptyStruct SPICE_GNUC_UNUSED spice_recorder_ ## rec = {}
#define RECORDER_TRACE(rec) \
    (sizeof(spice_recorder_ ## rec) != sizeof(SpiceEmptyStruct))
#define RECORDER_TWEAK_DECLARE(rec) \
    extern const SpiceDummyTweak spice_recorder_tweak_ ## rec
#define RECORDER_TWEAK_DEFINE(rec, value, comment) \
    const SpiceDummyTweak spice_recorder_tweak_ ## rec = { (value) }
#define RECORDER_TWEAK(rec) \
    ((spice_recorder_tweak_ ## rec).tweak_value)
#define RECORD(rec, ...) do { \
        if (sizeof((spice_recorder_ ## rec).dummy)) printf(__VA_ARGS__); \
    } while(0)
#define RECORD_TIMING_BEGIN(rec) \
    do { RECORD(rec, "begin");
#define RECORD_TIMING_END(rec, op, name, value) \
        RECORD(rec, "end" op name); \
    } while(0)
#define record(...) \
    RECORD(__VA_ARGS__)
static inline void
recorder_dump_on_common_signals(unsigned add, unsigned remove)
{
}
#endif

#if !defined(ENABLE_AGENT_INTERFACE)
#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/* Stubs for Agent-Interface specific definitions */
static inline void
agent_interface_start(unsigned int port)
{
}

typedef void (*forward_quality_cb_t)(void *, const char *);
static inline void
agent_interface_set_forward_quality_cb(forward_quality_cb_t cb, void *data)
{
}

typedef int (*on_connect_cb_t)(void *);
static inline void
agent_interface_set_on_connect_cb(on_connect_cb_t cb, void *data)
{
}
#ifdef __cplusplus
}
#endif // __cplusplus
#endif
