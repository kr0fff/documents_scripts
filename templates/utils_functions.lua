function FilterExtra(str, extra)
    return str and str:gsub(extra, '') or nil
end
function StickTogether(str, sub, extra)
    local res = str.Value and str.Text .. ' ' .. sub.Text or sub.Text
    return FilterExtra(res, extra)
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('[%s%,]+', ''):match('%d+[%d%.]*')
    return decimal
            and ctx:CreateDecimal(decimal)
            or nil
end