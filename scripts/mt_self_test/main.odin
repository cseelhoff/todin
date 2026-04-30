package mt_self_test

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

// Standalone validator for the MersenneTwister algorithm we ship in
// odin_flat/org__apache__commons__math3__random__mersenne_twister.odin.
// This file embeds an identical copy of the algorithm so we can
// validate it against the captured Java reference vector WITHOUT
// having to compile the whole in-progress odin_flat package.
//
// Run:
//   odin run scripts/mt_self_test -- scripts/mt_reference_vector.txt
//
// If the embedded algorithm is later changed, copy the new procs from
// odin_flat verbatim into this file and re-run.

MT_N :: 624
MT_M :: 397
MT_MATRIX_A :: 0x9908b0df
MT_UPPER_MASK :: 0x80000000
MT_LOWER_MASK :: 0x7fffffff

Mt :: struct {
        mt:  [MT_N]u32,
        mti: i32,
}

mt_set_seed_int :: proc(self: ^Mt, seed: u32) {
        long_mt := u64(seed) & 0xffffffff
        self.mt[0] = u32(long_mt)
        for i: i32 = 1; i < MT_N; i += 1 {
                long_mt = (1812433253 * (long_mt ~ (long_mt >> 30)) + u64(i)) & 0xffffffff
                self.mt[i] = u32(long_mt)
        }
        self.mti = MT_N
}

mt_set_seed_array :: proc(self: ^Mt, seed: []u32) {
        mt_set_seed_int(self, 19650218)
        i: i32 = 1
        j: i32 = 0
        seed_len := i32(len(seed))
        k: i32 = MT_N if MT_N >= seed_len else seed_len
        for ; k != 0; k -= 1 {
                l0 := u64(self.mt[i])
                l1 := u64(self.mt[i - 1])
                l := (l0 ~ ((l1 ~ (l1 >> 30)) * 1664525)) + u64(seed[j]) + u64(j)
                self.mt[i] = u32(l & 0xffffffff)
                i += 1
                j += 1
                if i >= MT_N {
                        self.mt[0] = self.mt[MT_N - 1]
                        i = 1
                }
                if j >= seed_len {
                        j = 0
                }
        }
        for k = MT_N - 1; k != 0; k -= 1 {
                l0 := u64(self.mt[i])
                l1 := u64(self.mt[i - 1])
                l := (l0 ~ ((l1 ~ (l1 >> 30)) * 1566083941)) - u64(i)
                self.mt[i] = u32(l & 0xffffffff)
                i += 1
                if i >= MT_N {
                        self.mt[0] = self.mt[MT_N - 1]
                        i = 1
                }
        }
        self.mt[0] = 0x80000000
        self.mti = MT_N
}

mt_new_seeded :: proc(seed: i64) -> ^Mt {
        r := new(Mt)
        useed := transmute(u64)seed
        seed_arr: [2]u32 = {u32(useed >> 32), u32(useed & 0xffffffff)}
        mt_set_seed_array(r, seed_arr[:])
        return r
}

mt_next :: proc(self: ^Mt, bits: u32) -> u32 {
        if self.mti >= MT_N {
                mt_next_v := self.mt[0]
                for k: i32 = 0; k < MT_N - MT_M; k += 1 {
                        mt_curr := mt_next_v
                        mt_next_v = self.mt[k + 1]
                        y := (mt_curr & MT_UPPER_MASK) | (mt_next_v & MT_LOWER_MASK)
                        mag: u32 = 0 if (y & 1) == 0 else MT_MATRIX_A
                        self.mt[k] = self.mt[k + MT_M] ~ (y >> 1) ~ mag
                }
                for k: i32 = MT_N - MT_M; k < MT_N - 1; k += 1 {
                        mt_curr := mt_next_v
                        mt_next_v = self.mt[k + 1]
                        y := (mt_curr & MT_UPPER_MASK) | (mt_next_v & MT_LOWER_MASK)
                        mag: u32 = 0 if (y & 1) == 0 else MT_MATRIX_A
                        self.mt[k] = self.mt[k + (MT_M - MT_N)] ~ (y >> 1) ~ mag
                }
                y := (mt_next_v & MT_UPPER_MASK) | (self.mt[0] & MT_LOWER_MASK)
                mag: u32 = 0 if (y & 1) == 0 else MT_MATRIX_A
                self.mt[MT_N - 1] = self.mt[MT_M - 1] ~ (y >> 1) ~ mag
                self.mti = 0
        }
        y := self.mt[self.mti]
        self.mti += 1
        y ~= y >> 11
        y ~= (y << 7) & 0x9d2c5680
        y ~= (y << 15) & 0xefc60000
        y ~= y >> 18
        if bits >= 32 do return y
        return y >> (32 - bits)
}

mt_next_int :: proc(self: ^Mt) -> i32 {
        return transmute(i32)mt_next(self, 32)
}

mt_next_int_bounded :: proc(self: ^Mt, n: i32) -> i32 {
        assert(n > 0)
        neg_n := transmute(i32)(0 - transmute(u32)n)
        if (n & neg_n) == n {
                return i32((u64(transmute(u32)n) * u64(mt_next(self, 31))) >> 31)
        }
        for {
                bits := i32(mt_next(self, 31))
                val := bits % n
                if bits - val + (n - 1) >= 0 do return val
        }
}

main :: proc() {
        path := "scripts/mt_reference_vector.txt"
        if len(os.args) >= 2 do path = os.args[1]
        data, err := os.read_entire_file_from_path(path, context.allocator)
        if err != nil {
                fmt.eprintln("cannot read", path, "err=", err)
                os.exit(2)
        }
        sections: map[string][]string
        for line in strings.split_lines(string(data)) {
                if len(line) == 0 do continue
                colon := strings.index(line, ":")
                if colon < 0 do continue
                sections[strings.trim_space(line[:colon])] =
                    strings.split(strings.trim_space(line[colon + 1:]), ",")
        }
        fails := 0

        {
                refs := sections["raw32"]
                r := mt_new_seeded(42)
                for s, i in refs {
                        want, _ := strconv.parse_u64(s)
                        got := u64(transmute(u32)mt_next_int(r))
                        if want != got {
                                if fails < 5 do fmt.eprintfln("raw32[%d]: want=%d got=%d", i, want, got)
                                fails += 1
                        }
                }
                fmt.println("raw32:", len(refs), "values, cumulative fails:", fails)
        }
        prev := fails
        {
                refs := sections["nextInt6"]
                r := mt_new_seeded(42)
                for s, i in refs {
                        want, _ := strconv.parse_int(s)
                        got := mt_next_int_bounded(r, 6)
                        if i32(want) != got {
                                if fails - prev < 5 do fmt.eprintfln("nextInt6[%d]: want=%d got=%d", i, want, got)
                                fails += 1
                        }
                }
                fmt.println("nextInt6:", len(refs), "values, cumulative fails:", fails)
        }
        prev = fails
        {
                refs := sections["nextInt12"]
                r := mt_new_seeded(42)
                for s, i in refs {
                        want, _ := strconv.parse_int(s)
                        got := mt_next_int_bounded(r, 12)
                        if i32(want) != got {
                                if fails - prev < 5 do fmt.eprintfln("nextInt12[%d]: want=%d got=%d", i, want, got)
                                fails += 1
                        }
                }
                fmt.println("nextInt12:", len(refs), "values, cumulative fails:", fails)
        }
        prev = fails
        {
                refs := sections["nextInt8"]
                r := mt_new_seeded(42)
                for s, i in refs {
                        want, _ := strconv.parse_int(s)
                        got := mt_next_int_bounded(r, 8)
                        if i32(want) != got {
                                if fails - prev < 5 do fmt.eprintfln("nextInt8[%d]: want=%d got=%d", i, want, got)
                                fails += 1
                        }
                }
                fmt.println("nextInt8:", len(refs), "values, cumulative fails:", fails)
        }
        if fails == 0 {
                fmt.println("PASS: MersenneTwister Odin port matches Java reference")
                os.exit(0)
        }
        fmt.eprintln("FAIL:", fails, "mismatches")
        os.exit(1)
}
