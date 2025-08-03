/* -*- Mode: C; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/*
   Copyright (C) 2010, 2011, 2018 Red Hat, Inc.

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

#ifndef H_SPICE_COMMON_UTILS
#define H_SPICE_COMMON_UTILS

#include <glib.h>
#include <glib-object.h>
#include <stdint.h>

G_BEGIN_DECLS

const char *spice_genum_get_nick(GType enum_type, gint value);
int spice_genum_get_value(GType enum_type, const char *nick,
                          gint default_value);

#define BIT_BYTE(nr)            ((nr) / 8)
#define BIT_MASK(nr)            (1 << ((nr) % 8))

/**
 * set_bitmap - Set a bit in memory
 * @nr: the bit to set
 * @addr: the address to start counting from
 */
static inline void set_bitmap(uint32_t nr, uint8_t *addr)
{
    addr[BIT_BYTE(nr)] |= BIT_MASK(nr);
}

/**
 * test_bitmap - Determine whether a bit is set
 * @nr: bit number to test
 * @addr: Address to start counting from
 */
static inline int test_bitmap(uint32_t nr, const uint8_t *addr)
{
    return 1 & (addr[BIT_BYTE(nr)] >> (nr % 8));
}

G_END_DECLS

#endif //H_SPICE_COMMON_UTILS
