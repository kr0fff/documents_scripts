function PostExtract(fields, tables, ctx)
    if fields.InvoiceDate then
        local month, year = fields.InvoiceDate.Value.Month, fields.InvoiceDate.Value.Year
        month = monthToText(month)
        fields.InvoiceNumber = 'OPE Claim - ' .. month .. year
    end
end
function monthToText(monthNumber)
    local monthNames = { [1] = 'Jan', [2] = 'Feb', [3] = 'Mar', [4] = 'Apr', [5] = 'May', [6] = 'Jun', [7] = 'Jul', [8] = 'Aug', [9] = 'Sep', [10] = 'Oct', [11] = 'Nov', [12] = 'Dec' }
    return monthNames[monthNumber]
end