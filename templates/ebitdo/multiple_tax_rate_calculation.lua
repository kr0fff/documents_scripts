function PostExtract(fields, tables, ctx)
    local zero = ctx:CreateDecimal('0.00')
    local merged = ctx:CreateTable()
    merged:AppendColumn('Subtotal')
    merged:AppendColumn('Tax')
    merged:AppendColumn('Total')
    merged:AppendColumn('TaxPercent')
    tables['MergedVatLineItems'] = merged
    if fields.InvoiceSubtotal and fields.InvoiceTotal then
        local text = ctx['text']
        text = text:GetArea(
                text.BBox.Left,
                fields.InvoiceSubtotal.BBox.Bottom,
                text.BBox.Right,
                fields.InvoiceTotal.BBox.Top
        )
        if text.Length > 0 then
            local lastPair = { rate = nil, total = nil }
            for i = 0, text.Length - 1 do
                local line = text[i]:ToString()
                local pvmRate = line:match('PVM%s+suma%s+(%d+)')
                local pvmTotal = line:match('(%d+%.%d%d)$')

                if pvmRate then
                    lastPair.rate = ctx:CreateDecimal(pvmRate) or nil
                else
                    if pvmTotal and lastPair.rate and not lastPair.total then
                        lastPair.total = ctx:CreateDecimal(pvmTotal) or nil
                    end
                end
                if lastPair.rate and lastPair.total then
                    if lastPair.rate == 21 then
                        local total = fields.InvoiceSubtotal + fields.InvoiceTax
                        merged:AppendRow()
                        merged[-1].Subtotal = fields.InvoiceSubtotal:Round(2)
                        merged[-1].Tax = fields.InvoiceTax:Round(2)
                        merged[-1].Total = total:Round(2)
                        merged[-1].TaxPercent = fields.VatTariff
                    elseif lastPair.total ~= zero then
                        local subtotal = lastPair.total / (lastPair.rate / 100)
                        merged:AppendRow()
                        merged[-1].Subtotal = subtotal
                        merged[-1].Tax = lastPair.total
                        merged[-1].Total = subtotal + lastPair.total
                        merged[-1].TaxPercent = lastPair.rate
                    end
                    lastPair.total = nil
                    lastPair.rate = nil
                end
            end
        end
    end
end
function Finalize(fields, tables, ctx)
    if fields.CustomerName then
        local name = fields.CustomerName.Text:gsub('^[%s%:]+', ''):match('^([%a%d%s]+)%s+%,')
        if name then
            fields.CustomerName = name
        end
    end
end