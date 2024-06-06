function PostExtract(fields, tables, ctx)
    if fields._Net and fields._Income and not fields.InvoiceTotal then
        fields.InvoiceTotal = fields._Net - fields._Income
    end
    if fields.VatTariff then
        fields.VatTariff = CastToDecimal(fields.VatTariff.Text, ctx)
    end
    if fields._CustomerAnchor then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = text.BBox.Left
        local y0 = fields._CustomerAnchor.BBox.Bottom + h * 2
        local x1 = text.BBox.Right
        local y1 = fields._CustomerAnchor.BBox.Bottom + h * 6
        text = text:GetArea(x0, y0, x1, y1)
        if text.Length > 1 then
            local customer = text[0]:ToString()
            for i = 1, text.Length - 1 do
                local code, taxId = text[i]:ToString():match('(%d+)%s+([A-Z][A-Z]%d+)')
                local onlyCode = text[i]:ToString():match('^%d+$')
                if code and taxId then
                    fields.CustomerCode = code
                    fields.CustomerTaxId = taxId
                    fields.CustomerName = customer
                    break
                elseif onlyCode and onlyCode:len() >= 9 then
                    fields.CustomerCode = onlyCode
                    fields.CustomerName = customer
                    break
                end
            end
        end
    end
    if fields._Anchor0 then
        local items = ctx:CreateTable()
        items:AppendColumn('Description')
        items:AppendColumn('Qty')
        items:AppendColumn('UOM')
        items:AppendColumn('UnitPriceIncTax')
        items:AppendColumn('Tax')
        items:AppendColumn('TaxPercent')
        items:AppendColumn('Total')
        tables['LineItems'] = items
        local text = ctx['text']
        local h = text.AvgWordHeight
        local bias = text.AvgWordHeight * 4
        local x1 = fields._Anchor1 and fields._Anchor1.BBox.Right + bias or text.BBox.Right
        local y1 = fields._Anchor1 and fields._Anchor1.BBox.Top or fields.InvoiceSubtotal and fields.InvoiceSubtotal.BBox.Top or text.BBox.Bottom
        text = text:GetArea(text.BBox.Left, fields._Anchor0.BBox.Bottom + h, x1, y1)
        local descriptionIndex
        local priceIndex
        local item = { Description = nil, Qty = nil, UOM = nil, UnitPriceIncTax = nil, Tax = nil, TaxPercent = nil, Total = nil }
        if text.Length > 0 then
            local s = ''
            for i = 0, text.Length - 1 do
                s = s .. ' || ' .. text[i]:ToString()
                local line = text[i]:ToString()
                local price, qty, uom = line:match('([%d%,%.]+)[Xx%s]+([%d%,%.]+)%s+([A-Za-z%d%|]+)')
                local description, total = line:match('([%a%A%s%p%d]+)%s+([%d%,%.]+%d%d)%s+[AC]')
                local discount = line:match('NUOLAIDA%s+([%-%,%.%d]+%d%d)%s+[AC]')
                if line:match('Mokėti') or line:match('MOKETI') or line:match('Mokėta') then
                    break
                end
                if discount then
                    items:AppendRow()
                    items[-1].Description = 'Nuolaida'
                    items[-1].Qty = ctx:CreateDecimal('1.00')
                    items[-1].UnitPriceIncTax = CastToDecimal(discount, ctx)
                    items[-1].Tax = ctx:CreateDecimal('0.00')
                    items[-1].TaxPercent = ctx:CreateDecimal('0.00')
                    items[-1].Total = CastToDecimal(discount, ctx)
                    s = s .. ' : DISCOUNT MATCHED'
                end
                if price and qty and uom then
                    priceIndex = i
                    item.Qty = CastToDecimal(qty, ctx)
                    item.UOM = uom
                    item.UnitPriceIncTax = CastToDecimal(price, ctx)
                    s = s .. ' : UNITS MATCHED'
                end
                if description and description:len() >= 5 and total and not discount then
                    descriptionIndex = i
                    item.Description = description
                    item.Total = CastToDecimal(total, ctx)
                    s = s .. ' : DETAILS MATCHED'
                end
                if priceIndex and descriptionIndex then
                    items:AppendRow()
                    local subtotal = item.Total and fields.VatTariff and item.Total / (1 + fields.VatTariff.Value / 100) or nil
                    local tax = subtotal and fields.VatTariff and subtotal * (fields.VatTariff.Value / 100) or nil
                    items[-1].Description = item.Description
                    items[-1].Qty = item.Qty
                    items[-1].UOM = item.UOM
                    items[-1].UnitPriceIncTax = item.UnitPriceIncTax
                    items[-1].Tax = tax and tax:Round(2) or nil
                    items[-1].TaxPercent = fields.VatTariff or nil
                    items[-1].Total = item.Total
                    for it in pairs(item) do
                        item[it] = nil
                    end
                    priceIndex = nil
                    descriptionIndex = nil
                    s = s .. ' : ROW ADDED'
                end
            end --[[fields.Output = s]]
        end
    end
end
function Finalize(fields, tables, ctx)
    if fields.InvoiceTotal and fields.InvoiceTax and fields.VatTariff and not fields.InvoiceSubtotal then
        fields.InvoiceSubtotal = fields.InvoiceTotal - fields.InvoiceTax
    elseif fields.InvoiceSubtotal and fields.InvoiceTax and fields.VatTariff and not fields.InvoiceTotal then
        fields.InvoiceTotal = fields.InvoiceSubtotal + fields.InvoiceTax
    end
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('%,+', '.'):match('^[%-%d%.]+$')
    if decimal then
        local value = ctx:CreateDecimal(decimal)
        return value and value:Round(2) or nil
    else
        return nil
    end
end