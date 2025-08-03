#pragma once

// *****************************************************************************
// This software is licensed under the GNU Lesser General Public License v2+
// (C) 2017-2019, Christophe de Dinechin <christophe@dinechin.org>
// *****************************************************************************
// This file was part of Recorder
//
// Recorder is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// Recorder is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Recorder, in a file named COPYING.
// If not, see <https://www.gnu.org/licenses/>.
// *****************************************************************************
/* This file is based on Recorder's recorder.h file, that describes a general-
 * purpose instrumentation interface. agent_interface.h is a trimmed-down
 * version of it. */

#include <stdarg.h>
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

static inline void
recorder_dump_on_common_signals(unsigned add, unsigned remove)
{
}

// ============================================================================
//
//    Recorder data structures
//
// ============================================================================

typedef struct recorder_entry
/// ---------------------------------------------------------------------------
///   Entry in the flight recorder.
///----------------------------------------------------------------------------
///  Notice that the arguments are stored as "intptr_t" because that type
///  is guaranteed to be the same size as a pointer. This allows us to
///  properly align recorder entries to powers of 2 for efficiency.
///  Also read explanations of \ref _recorder_double and \ref _recorder_float
///  below regarding how to use floating-point with the recorder.
{
    const char *format;         ///< Printf-style format for record + file/line
    uintptr_t   timestamp;      ///< Time at which record took place
    const char *where;          ///< Source code function
    uintptr_t   args[4];        ///< Four arguments, for a total of 8 fields
} recorder_entry;


/// A global counter indicating the order of entries across recorders.
/// this is incremented atomically for each record() call.
/// It must be exposed because all XYZ_record() implementations need to
/// touch the same shared variable in order to provide a global order.
extern uintptr_t recorder_order;

typedef struct recorder_info
///----------------------------------------------------------------------------
///   A linked list of the activated recorders
///----------------------------------------------------------------------------
{
    intptr_t                trace;      ///< Trace this recorder
    const char *            name;       ///< Name of this parameter / recorder
    const char *            description;///< Description of what is recorded
    recorder_entry          data[0];    ///< Data for this recorder
} recorder_info;

// ============================================================================
//
//   Adding data to a recorder
//
// ============================================================================

extern void recorder_append(recorder_info *rec,
                            const char *where,
                            const char *format,
                            uintptr_t a0,
                            uintptr_t a1,
                            uintptr_t a2,
                            uintptr_t a3);
extern void recorder_append2(recorder_info *rec,
                             const char *where,
                             const char *format,
                             uintptr_t a0,
                             uintptr_t a1,
                             uintptr_t a2,
                             uintptr_t a3,
                             uintptr_t a4,
                             uintptr_t a5,
                             uintptr_t a6,
                             uintptr_t a7);
extern void recorder_append3(recorder_info *rec,
                             const char *where,
                             const char *format,
                             uintptr_t a0,
                             uintptr_t a1,
                             uintptr_t a2,
                             uintptr_t a3,
                             uintptr_t a4,
                             uintptr_t a5,
                             uintptr_t a6,
                             uintptr_t a7,
                             uintptr_t a8,
                             uintptr_t a9,
                             uintptr_t a10,
                             uintptr_t a11);

/// Activate a recorder (during construction time)
extern void recorder_activate(recorder_info *recorder);

// ============================================================================
//
//    Declaration of recorders and tweaks
//
// ============================================================================

#define RECORDER_DECLARE(Name)                                          \
/* ----------------------------------------------------------------*/   \
/*  Declare a recorder with the given name (for use in headers)    */   \
/* ----------------------------------------------------------------*/   \
    extern recorder_info * const recorder_info_ptr_for_##Name;          \
    extern struct recorder_info_for_##Name recorder_info_for_##Name


// ============================================================================
//
//    Definition of recorders and tweaks
//
// ============================================================================

#define RECORDER(Name, Size, Info)      RECORDER_DEFINE(Name,Size,Info)

#define RECORDER_DEFINE(Name, Size, Info)                               \
/*!----------------------------------------------------------------*/   \
/*! Define a recorder type with Size elements                      */   \
/*!----------------------------------------------------------------*/   \
/*! \param Name is the C name fo the recorder.                          \
 *! \param Size is the number of entries in the circular buffer.        \
 *! \param Info is a description of the recorder for help. */           \
                                                                        \
/* The entry in linked list for this type */                            \
struct recorder_info_for_##Name                                         \
{                                                                       \
    recorder_info       info;                                           \
    recorder_entry      data[Size];                                     \
}                                                                       \
recorder_info_for_##Name =                                              \
{                                                                       \
    {                                                                   \
        0, #Name, Info, {}                                              \
    },                                                                  \
    {}                                                                  \
};                                                                      \
recorder_info * const recorder_info_ptr_for_##Name =                    \
    &recorder_info_for_##Name.info;                                     \
                                                                        \
RECORDER_CONSTRUCTOR                                                    \
static void recorder_activate_##Name(void)                              \
/* ----------------------------------------------------------------*/   \
/*  Activate recorder before entering main()                       */   \
/* ----------------------------------------------------------------*/   \
{                                                                       \
    recorder_activate(RECORDER_INFO(Name));                             \
}                                                                       \
                                                                        \
/* Purposefully generate compile error if macro not followed by ; */    \
extern void recorder_activate(recorder_info *recorder)

typedef struct SpiceDummyTweak {
    intptr_t tweak_value;
} SpiceDummyTweak;

typedef struct SpiceEmptyStruct {
    char dummy[0];
} SpiceEmptyStruct;

#define RECORDER_TWEAK_DECLARE(rec) \
    extern const SpiceDummyTweak spice_recorder_tweak_ ## rec

#define RECORDER_TWEAK_DEFINE(rec, value, comment) \
    const SpiceDummyTweak spice_recorder_tweak_ ## rec = { (value) }

#define RECORDER_TWEAK(rec) \
    ((spice_recorder_tweak_ ## rec).tweak_value)

#define RECORDER_TRACE(rec) \
    (sizeof(struct recorder_info_for_ ## rec) != sizeof(SpiceEmptyStruct))


// ============================================================================
//
//    Access to recorder and tweak info
//
// ============================================================================

#define RECORDER_INFO(Name)     (recorder_info_ptr_for_##Name)

// ============================================================================
//
//    Recording stuff
//
// ============================================================================

#define record(Name, ...)               RECORD_MACRO(Name, __VA_ARGS__)
#define RECORD(Name,...)                RECORD_MACRO(Name, __VA_ARGS__)
#define RECORD_MACRO(Name, ...)                                  \
    RECORD_(RECORD,RECORD_COUNT_(__VA_ARGS__),Name,__VA_ARGS__)
#define RECORD_(RECORD,RCOUNT,Name,...)                          \
    RECORD__(RECORD,RCOUNT,Name,__VA_ARGS__)
#define RECORD__(RECORD,RCOUNT,Name,...)                         \
    RECORD##RCOUNT(Name,__VA_ARGS__)
#define RECORD_COUNT_(...)      RECORD_COUNT__(Dummy,##__VA_ARGS__,_X,_X,_12,_11,_10,_9,_8,_7,_6,_5,_4,_3,_2,_1,_0)
#define RECORD_COUNT__(Dummy,_0,_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_N,...)      _N

#define RECORD_0(Name, Format)                          \
    recorder_append(RECORDER_INFO(Name),                \
                    RECORDER_SOURCE_FUNCTION,           \
                    RECORDER_SOURCE_LOCATION            \
                    Format, 0, 0, 0, 0)
#define RECORD_1(Name, Format, a)                       \
    recorder_append(RECORDER_INFO(Name),                \
                    RECORDER_SOURCE_FUNCTION,           \
                    RECORDER_SOURCE_LOCATION            \
                    Format,                             \
                    RECORDER_ARG(a), 0, 0, 0)
#define RECORD_2(Name, Format, a,b)                     \
    recorder_append(RECORDER_INFO(Name),                \
                    RECORDER_SOURCE_FUNCTION,           \
                    RECORDER_SOURCE_LOCATION            \
                    Format,                             \
                    RECORDER_ARG(a),                    \
                    RECORDER_ARG(b), 0, 0)
#define RECORD_3(Name, Format, a,b,c)                   \
    recorder_append(RECORDER_INFO(Name),                \
                    RECORDER_SOURCE_FUNCTION,           \
                    RECORDER_SOURCE_LOCATION            \
                    Format,                             \
                    RECORDER_ARG(a),                    \
                    RECORDER_ARG(b),                    \
                    RECORDER_ARG(c), 0)
#define RECORD_4(Name, Format, a,b,c,d)                 \
    recorder_append(RECORDER_INFO(Name),                \
                    RECORDER_SOURCE_FUNCTION,           \
                    RECORDER_SOURCE_LOCATION            \
                    Format,                             \
                    RECORDER_ARG(a),                    \
                    RECORDER_ARG(b),                    \
                    RECORDER_ARG(c),                    \
                    RECORDER_ARG(d))
#define RECORD_5(Name, Format, a,b,c,d,e)               \
    recorder_append2(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e), 0, 0, 0)
#define RECORD_6(Name, Format, a,b,c,d,e,f)             \
    recorder_append2(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e),                   \
                     RECORDER_ARG(f), 0, 0)
#define RECORD_7(Name, Format, a,b,c,d,e,f,g)           \
    recorder_append2(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e),                   \
                     RECORDER_ARG(f),                   \
                     RECORDER_ARG(g), 0)
#define RECORD_8(Name, Format, a,b,c,d,e,f,g,h)         \
    recorder_append2(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e),                   \
                     RECORDER_ARG(f),                   \
                     RECORDER_ARG(g),                   \
                     RECORDER_ARG(h))
#define RECORD_9(Name, Format, a,b,c,d,e,f,g,h,i)       \
    recorder_append3(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e),                   \
                     RECORDER_ARG(f),                   \
                     RECORDER_ARG(g),                   \
                     RECORDER_ARG(h),                   \
                     RECORDER_ARG(i), 0,0,0)
#define RECORD_10(Name, Format, a,b,c,d,e,f,g,h,i,j)    \
    recorder_append3(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e),                   \
                     RECORDER_ARG(f),                   \
                     RECORDER_ARG(g),                   \
                     RECORDER_ARG(h),                   \
                     RECORDER_ARG(i),                   \
                     RECORDER_ARG(j), 0,0)
#define RECORD_11(Name, Format, a,b,c,d,e,f,g,h,i,j,k)  \
    recorder_append3(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e),                   \
                     RECORDER_ARG(f),                   \
                     RECORDER_ARG(g),                   \
                     RECORDER_ARG(h),                   \
                     RECORDER_ARG(i),                   \
                     RECORDER_ARG(j),                   \
                     RECORDER_ARG(k),0)
#define RECORD_12(Name,Format,a,b,c,d,e,f,g,h,i,j,k,l)  \
    recorder_append3(RECORDER_INFO(Name),               \
                     RECORDER_SOURCE_FUNCTION,          \
                     RECORDER_SOURCE_LOCATION           \
                     Format,                            \
                     RECORDER_ARG(a),                   \
                     RECORDER_ARG(b),                   \
                     RECORDER_ARG(c),                   \
                     RECORDER_ARG(d),                   \
                     RECORDER_ARG(e),                   \
                     RECORDER_ARG(f),                   \
                     RECORDER_ARG(g),                   \
                     RECORDER_ARG(h),                   \
                     RECORDER_ARG(i),                   \
                     RECORDER_ARG(j),                   \
                     RECORDER_ARG(k),                   \
                     RECORDER_ARG(l))
#define RECORD_X(Name, ...)   RECORD_TOO_MANY_ARGS(printf(__VA_ARGS__))


// Some ugly macro drudgery to make things easy to use. Adjust type.
#ifdef __cplusplus
#define RECORDER_ARG(arg)       _recorder_arg(arg)
#else // !__cplusplus

#if defined(__GNUC__) && !defined(__clang__)
#  if __GNUC__ <= 4 || (__GNUC__ == 4 && __GNUC_MINOR__ < 9)
#    define RECORDER_WITHOUT_GENERIC
#  endif
#endif // __GNUC__

#ifdef RECORDER_WITHOUT_GENERIC
#define RECORDER_ARG(arg) ((uintptr_t) (arg))
#else // !RECORDER_WITHOUT_GENERIC
#define RECORDER_ARG(arg)                               \
    _Generic(arg,                                       \
             unsigned char:     _recorder_unsigned,     \
             unsigned short:    _recorder_unsigned,     \
             unsigned:          _recorder_unsigned,     \
             unsigned long:     _recorder_unsigned,     \
             unsigned long long:_recorder_unsigned,     \
             char:              _recorder_char,         \
             signed char:       _recorder_signed,       \
             signed short:      _recorder_signed,       \
             signed:            _recorder_signed,       \
             signed long:       _recorder_signed,       \
             signed long long:  _recorder_signed,       \
             float:             _recorder_float,        \
             double:            _recorder_double,       \
             default:           _recorder_pointer)(arg)
#endif // RECORDER_WITHOUT_GENERIC
#endif // __cplusplus

// ============================================================================
//
//    Timing information
//
// ============================================================================

#define RECORD_TIMING_BEGIN(rec) \
    do { RECORD(rec, "begin");
#define RECORD_TIMING_END(rec, op, name, value) \
        RECORD(rec, "end" op name); \
    } while (0)


// ============================================================================
//
//   Support macros
//
// ============================================================================

#define RECORDER_SOURCE_FUNCTION    __func__ /* Works in C99 and C++11 */
#define RECORDER_SOURCE_LOCATION    __FILE__ ":" RECORDER_STRING(__LINE__) ":"
#define RECORDER_STRING(LINE)       RECORDER_STRING_(LINE)
#define RECORDER_STRING_(LINE)      #LINE

#ifdef __GNUC__
#define RECORDER_CONSTRUCTOR            __attribute__((constructor))
#else
#define RECORDER_CONSTRUCTOR
#endif

#ifdef __cplusplus
}
#endif // __cplusplus

// ============================================================================
//
//    Utility: Convert floating point values for vararg format
//
// ============================================================================
//
//   The recorder stores only uintptr_t in recorder entries. Integer types
//   are promoted, pointer types are converted. Floating point values
//   are converted a floating point type of the same size as uintptr_t,
//   i.e. float are converted to double on 64-bit platforms, and conversely.

#ifdef __cplusplus
#include <string>

// In C++, we don't use _Generic but actual overloading
template <class inttype>
static inline uintptr_t         _recorder_arg(inttype i)
{
    return (uintptr_t) i;
}


static inline uintptr_t         _recorder_arg(const std::string &arg)
{
    return (uintptr_t) arg.c_str();
}
#define _recorder_float         _recorder_arg
#define _recorder_double        _recorder_arg

#else // !__cplusplus

static inline uintptr_t _recorder_char(char c)
// ----------------------------------------------------------------------------
//   Necessary because of the way generic selections work
// ----------------------------------------------------------------------------
{
    return c;
}


static inline uintptr_t _recorder_unsigned(uintptr_t i)
// ----------------------------------------------------------------------------
//   Necessary because of the way generic selections work
// ----------------------------------------------------------------------------
{
    return i;
}


static inline uintptr_t _recorder_signed(intptr_t i)
// ----------------------------------------------------------------------------
//   Necessary because of the way generic selections work
// ----------------------------------------------------------------------------
{
    return (uintptr_t) i;
}


static inline uintptr_t _recorder_pointer(const void *i)
// ----------------------------------------------------------------------------
//   Necessary because of the way generic selections work
// ----------------------------------------------------------------------------
{
    return (uintptr_t) i;
}

#endif // __cplusplus


static inline uintptr_t _recorder_float(float f)
// ----------------------------------------------------------------------------
//   Convert floating point number to intptr_t representation for recorder
// ----------------------------------------------------------------------------
{
    if (sizeof(float) == sizeof(intptr_t)) {
        union { float f; uintptr_t i; } u;
        u.f = f;
        return u.i;
    } else {
        union { double d; uintptr_t i; } u;
        u.d = (double) f;
        return u.i;
    }
}


static inline uintptr_t _recorder_double(double d)
// ----------------------------------------------------------------------------
//   Convert double-precision floating point number to intptr_t representation
// ----------------------------------------------------------------------------
{
    if (sizeof(double) == sizeof(intptr_t)) {
        union { double d; uintptr_t i; } u;
        u.d = d;
        return u.i;
    } else {
        // Better to lose precision than not store any data
        union { float f; uintptr_t i; } u;
        u.f = d;
        return u.i;
    }
}

// ============================================================================
//   Agent-Interface specific definitions
// ============================================================================

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

// launch the Agent-Interface server socket
extern void agent_interface_start(unsigned int port);

//
typedef void (*forward_quality_cb_t)(void *, const char *);
extern void agent_interface_set_forward_quality_cb(forward_quality_cb_t cb, void *data);

// set a callback function triggered when a new client connects to the socket
typedef int (*on_connect_cb_t)(void *);
extern void agent_interface_set_on_connect_cb(on_connect_cb_t cb, void *data);
#ifdef __cplusplus
}
#endif // __cplusplus
