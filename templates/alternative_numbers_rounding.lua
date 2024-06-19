function PostExtract(fields, tables, ctx)
    if fields._InvoiceSubtotal then
        fields.InvoiceSubtotal = CastToDecimal(fields._InvoiceSubtotal.Text, ctx)
    end
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('%s+', ''):gsub('%,+', '.')
    local value = tostring(RoundNumber(decimal, 2))
    return ctx:CreateDecimal(value) or nil
end
function RoundNumber(num, numDecimalPlaces)
    return tonumber(string.format('%.' .. (numDecimalPlaces or 0) .. 'f', num))
end