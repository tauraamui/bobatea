module bobatea

type Border = string

pub const top = Border('─')
pub const bottom = Border('─')
pub const left = Border('│')
pub const right = Border('│')
pub const top_left = Border('┌')
pub const top_right = Border('┐')
pub const bottom_left = Border('└')
pub const bottom_right = Border('┘')
pub const middle_left = Border('├')
pub const middle_right = Border('┤')
pub const middle = Border('┼')
pub const middle_top = Border('┬')
pub const middle_bottom = Border('┴')
