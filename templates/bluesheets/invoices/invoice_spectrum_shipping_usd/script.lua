function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local items = tables.LineItems
        items:RenameColumnHeader('UnitPrice', 'Unit Price')
        items:RenameColumnHeader('Qty', 'Quantity')
        items:RenameColumnHeader('Total', 'Amount')
        items:RenameColumnHeader('CurrencyCode', 'Currency')
        local period = fields.Period and fields.Period.Text:gsub('^[%s%:]+', '') or nil
        for i = 0, items.Length - 1 do
            local less = items[i].Description.Text:match('^Less')
            local lessRate = items[i].UnitPrice.Text:match('[%d%,]+')
            if less and lessRate and items[i].Total.Value then
                local rate = CastToDecimal(lessRate, ctx, true)
                items[i].Description = rate and items[i].Description.Value and 'Less Commission - ' .. rate .. ' %' or nil
                items[i].UnitPrice = items[i].Total.Value * -1
                items[i].Qty = 1
                items[i].Total = items[i].Total.Value * -1
            else
                items[i].Description = items[i].Description.Value and period and items[i].Description.Text .. ' - ' .. period or items[i].Description.Text or nil
                items[i].UnitPrice = items[i].UnitPrice.Value and CastToDecimal(items[i].UnitPrice.Text, ctx, false)
                items[i].Qty = items[i].Qty.Value and CastToDecimal(items[i].Qty.Text, ctx, false)
            end
            if (not items[i].Description.Value or items[i].Description.Value and string.len(items[i].Description.Text) == 0) and i > 0 and items[i - 1].Description.Value then
                items[i].Description = items[i - 1].Description.Text
            end
            if items[i].Total.Value and not items[i].UnitPrice.Value then
                items[i].UnitPrice = items[i].Total.Value
                items[i].Qty = 1
            end
        end
    end
end
function CastToDecimal(str, ctx, isNotCurrency)
    local decimal = str:gsub('%,+', '.'):gsub('%s+', ''):match('[%d%.]+')
    if decimal and not decimal:match('%.%d%d$') and isNotCurrency then
        if decimal:match('%.%d$') then
            decimal = decimal .. '0'
        else
            decimal = decimal .. '.00'
        end
    end
    if decimal then
        return isNotCurrency and decimal or ctx:CreateDecimal(decimal)
    else
        return nil
    end
end