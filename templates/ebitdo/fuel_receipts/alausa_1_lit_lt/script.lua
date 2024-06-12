function PostExtract(fields, tables, ctx)
    if fields.VatTariff then
        fields.VatTariff = CastToDecimal(fields.VatTariff.Text:gsub('%%', ''), ctx)
    end
    if not fields.CustomerName then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = text.BBox.Left
        local y0 = fields._CustomerAnchor and fields._CustomerAnchor.BBox.Bottom + h * 2 or text.BBox.Top
        local x1 = text.BBox.Right
        local y1 = fields._CustomerAnchorBottom and fields._CustomerAnchorBottom.BBox.Top or text.BBox.Bottom
        text = text:GetArea(x0, y0, x1, y1)
        if text.Length > 1 then
            for i = 1, text.Length - 1 do
                local supplierId = 'LT836156219'
                local supplierCode = '183615620'
                local code, taxId = text[i]:ToString():match('(%d+)%s+([A-Z][A-Z]%d+)')
                local onlyCode = text[i]:ToString():match('^%d+$')
                if code and taxId and code:len() >= 8 and taxId:len() >= 9 and taxId ~= supplierId then
                    fields.CustomerCode = code
                    fields.CustomerTaxId = taxId
                    fields.CustomerName = text[i - 1]:ToString()
                    break
                elseif onlyCode and onlyCode:len() >= 9 and onlyCode ~= supplierCode then
                    fields.CustomerCode = onlyCode
                    fields.CustomerName = text[i - 1]:ToString()
                    break
                end
            end
        end
    end
    if not tables.LineItems then
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
        local y0 = fields._Anchor0 and fields._Anchor0.BBox.Bottom + h or text.BBox.Top + h * 4
        local y1 = fields._Anchor1 and fields._Anchor1.BBox.Top or fields.InvoiceSubtotal and fields.InvoiceSubtotal.BBox.Top or text.BBox.Bottom
        text = text:GetArea(text.BBox.Left, y0, text.BBox.Right, y1)
        local descriptionIndex
        local priceIndex
        local item = { Description = nil, Qty = nil, UOM = nil, UnitPriceIncTax = nil, Tax = nil, TaxPercent = nil, Total = nil }
        if text.Length > 0 then
            local s = ''
            for i = 0, text.Length - 1 do
                s = s .. ' || ' .. text[i]:ToString()
                local line = text[i]:ToString()
                local price, qty, uom = line:match('([%d%,%.]+)[Xx%s]+([%d%,%.]+)%s+([A-Za-z%d%|]+)')
                local price_v2, qty_v2, uom_v2, total_v2 = line:match('([%d%,%.]+)[Xx%s]+([%d%,%.]+)%s+([A-Za-z%d%|]+)%s+([%d%,%.]+%d%d)%s+[AC]')
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
                if price_v2 and qty_v2 and uom_v2 and total_v2 then
                    descriptionIndex = i
                    priceIndex = i
                    item.Description = i > 0 and text[i - 1]:ToString() or nil
                    item.Qty = CastToDecimal(qty_v2, ctx)
                    item.UOM = uom_v2
                    item.UnitPriceIncTax = CastToDecimal(price_v2, ctx)
                    item.Total = CastToDecimal(total_v2, ctx)
                    s = s .. ' : V2 ROW ADDED'
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
    if fields.Undef1 and fields.Undef2 then
        if fields.Undef1.Value > fields.Undef2.Value then
            fields.InvoiceSubtotal = fields.Undef1.Value
            fields.InvoiceTax = fields.Undef2.Value
        else
            fields.InvoiceSubtotal = fields.Undef2.Value
            fields.InvoiceTax = fields.Undef1.Value
        end
        fields.Undef1 = nil
        fields.Undef2 = nil
    end
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