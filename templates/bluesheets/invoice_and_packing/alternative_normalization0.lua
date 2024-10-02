function PostExtract(fields, tables, ctx)
    if fields._PackageTotals then
        local total, unit_total, unit, gw, nw, measurement = fields._PackageTotals.Text:match('^(%d+)([A-Z]+)%s+%d+([A-Z]+)%s+([%d%.]+)KGS%s+([%d%.]+)KGS%s+([%d%.]+)CBM$')
        fields.InvoiceTotal = total and CastToDecimal(total, ctx) or nil
        fields.UnitTotal = unit_total or nil
        fields.Unit = unit or nil
        fields.GrossWeight = gw and CastToDecimal(gw, ctx) or nil
        fields.NetWeight = nw and CastToDecimal(nw, ctx) or nil
        fields.Measurement = measurement and CastToDecimal(measurement, ctx) or nil
    end
end
function Finalize(fields, tables, ctx)
    if not fields.Transport then
        fields.Transport = 'Sea'
    end
    if fields.ETA then
        fields.ATA = fields.ETA
    end
    if fields.OceanVessel then
        local vessel, voyage = fields.OceanVessel.Text:match('^([%a%s]+)[%s%/]+([A-Z%d%p%s]+)$')
        fields.OceanVessel = vessel or fields.OceanVessel.Text
        fields.Voyage = voyage or nil
    end
    if fields.CountryOrigin then
        local placeReceipt, country = fields.CountryOrigin.Text:match('([A-Z%s%d%p]+)%s*%,%s*([A-Z%s%d%p]+)')
        fields.PlaceOfReceipt = placeReceipt or nil
        fields.CountryOrigin = country or nil
    end
    if fields.CountrySource then
        local placeDelivery, country = fields.CountrySource.Text:match('([A-Z%s%d%p]+)%s*%,%s*([A-Z%s%d%p]+)')
        fields.FinalDestination = placeDelivery or nil
        fields.CountrySource = country or nil
    end
    if tables.LineItems then
        local items = tables.LineItems
        items:AppendColumn('Type')
        items:AppendColumn('PoNumber')
        items:AppendColumn('PartNumber')
        if items[-1].Description.Text:match('TOTAL') then
            fields.Quantity = items[-1].Qty.Value or nil
            fields.CurrencyAmount = items[-1].Total.Value or nil
            items:RemoveRow(-1)
        end
        for i = 0, items.Length - 1 do
            items[i].PoNumber = fields.PoNumber or nil
            items[i].Type = 'Goods'
            local partNumber, description = items[i].Description.Text:match('^([A-Z%d]+)%s+(.+)$')
            items[i].PartNumber = partNumber or nil
            items[i].Description = description or nil
        end
        NormaliseLineItems(tables, items, ctx)
    end
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('[%s%,]+', ''):match('[%d%.]+')
    return decimal and ctx:CreateDecimal(decimal) or nil
end
function NormaliseLineItems(tables, table, ctx)
    local items = ctx:CreateTable()
    items:AppendColumn('No', 'No.')
    items:AppendColumn('PoNo', 'P/O No.')
    items:AppendColumn('PartNumber', 'Part Number')
    items:AppendColumn('Descriptions', 'Descriptions')
    items:AppendColumn('Model', 'Model')
    items:AppendColumn('Quantity', 'Quantity')
    items:AppendColumn('UnitPrice', 'Unit Price')
    items:AppendColumn('Amount', 'Amount')
    items:AppendColumn('Type', 'Type')
    tables['LineItems'] = items
    local linesCounter = 0
    for i = 0, table.Length - 1 do
        linesCounter = linesCounter + 1
        items:AppendRow()
        items[-1].No = table[i].ItemNo and table[i].ItemNo.Value and table[i].ItemNo.Text or linesCounter
        items[-1].Type = table[i].Type and table[i].Type.Value and table[i].Type.Text or nil
        items[-1].PartNumber = table[i].PartNumber and table[i].PartNumber.Value and table[i].PartNumber.Text or nil
        items[-1].PoNo = table[i].PoNumber and table[i].PoNumber.Value and table[i].PoNumber.Text or nil
        items[-1].Descriptions = table[i].Description and table[i].Description.Value and table[i].Description.Text or nil
        items[-1].Quantity = table[i].Qty and table[i].Qty.Value or nil
        items[-1].UnitPrice = table[i].UnitPrice and table[i].UnitPrice.Value or nil
        items[-1].Amount = table[i].Total and table[i].Total.Value or nil
    end
end