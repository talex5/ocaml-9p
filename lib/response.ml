(*
 * Copyright (C) 2015 David Scott <dave@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)
open Error
open Types

module Version = Request.Version

module Auth = struct
  type t = {
    aqid: Qid.t;
  }

  let sizeof t = Qid.sizeof t.aqid

  let write t buf = Qid.write t.aqid buf

  let read buf =
    Qid.read buf
    >>= fun (aqid, rest) ->
    return ( { aqid }, rest )
end

module Err = struct
  type t = {
    ename: string;
  }

  let sizeof t = 2 + (String.length t.ename)

  let write t buf =
    let ename = Data.of_string t.ename in
    Data.write ename buf

  let read buf =
    Data.read buf
    >>= fun (ename, rest) ->
    let ename = Data.to_string ename in
    return ({ ename }, rest)
end

module Flush = struct
  type t = unit

  let sizeof _ = 0

  let write t buf = return buf

  let read buf = return ((), buf)
end

module Attach = struct
  type t = {
    qid: Qid.t
  }

  let sizeof t = Qid.sizeof t.qid

  let write t buf = Qid.write t.qid buf

  let read buf =
    Qid.read buf
    >>= fun (qid, rest) ->
    return ({ qid }, rest)
end

module Walk = struct
  type t = {
    wqids: Qid.t list
  }

  let sizeof t = 2 + (List.fold_left (+) 0 (List.map (fun q -> Qid.sizeof q) t.wqids))

  let write t rest =
    Int16.write (List.length t.wqids) rest
    >>= fun rest ->
    let rec loop rest = function
      | [] -> return rest
      | wqid :: wqids ->
        Qid.write wqid rest
        >>= fun rest ->
        loop rest wqids in
    loop rest t.wqids

  let read rest =
    Int16.read rest
    >>= fun (nwqids, rest) ->
    let rec loop rest acc = function
      | 0 -> return (List.rev acc, rest)
      | n ->
        Qid.read rest
        >>= fun (wqid, rest) ->
        loop rest (wqid :: acc) (n - 1) in
    loop rest [] nwqids
    >>= fun (wqids, rest) ->
    return ( { wqids }, rest )
end

cstruct hdr {
  uint32_t size;
  uint8_t ty;
  uint16_t tag;
} as little_endian

type payload =
  | Version of Version.t
  | Auth of Auth.t
  | Err of Err.t
  | Flush of Flush.t
  | Attach of Attach.t
  | Walk of Walk.t

type t = {
  tag: int;
  payload: payload;
}

let sizeof t = sizeof_hdr + (match t.payload with
  | Version x -> Version.sizeof x
  | Auth x -> Auth.sizeof x
  | Err x -> Err.sizeof x
  | Flush x -> Flush.sizeof x
  | Attach x -> Attach.sizeof x
  | Walk x -> Walk.sizeof x
)
