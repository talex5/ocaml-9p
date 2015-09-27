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
open Result

module Version : sig

  type t = {
    msize: int32;
    version: string;
  }
  (** The payload of a version message *)

  include S.SERIALISABLE with type t := t
end

module Auth : sig

  type t = {
    aqid: string; (* 13 bytes long *)
  }
  (** The payload of an authentication response *)

  include S.SERIALISABLE with type t := t
end

module Err : sig

  type t = {
    ename: string;
  }
  (** The pauload of an error response *)

  include S.SERIALISABLE with type t := t
end

module Flush : sig
  type t = unit
  (** The payload of a flush response *)

  include S.SERIALISABLE with type t := t
end

type payload =
  | Version of Version.t
  | Auth of Auth.t
  | Err of Err.t
  | Flush of Flush.t

type t = {
  tag: int;
  payload: payload;
}

val sizeof: t -> int