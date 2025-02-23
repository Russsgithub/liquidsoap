(*****************************************************************************

  Liquidsoap, a programmable audio stream generator.
  Copyright 2003-2023 Savonet team

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details, fully stated in the COPYING
  file at the root of the liquidsoap distribution.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

 *****************************************************************************)

open Mm
open Video_converter
module Img = Image.Generic

let formats = [Img.Pixel.RGB Img.Pixel.RGBA32; Img.Pixel.YUV Img.Pixel.YUVJ420]
let convert src dst = Image.Generic.convert ~proportional:false src dst
let create () = convert

let () =
  Plug.register video_converters "native" ~doc:"Native image format converter."
    (formats, formats, create)
