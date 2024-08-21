function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local items = tables.LineItems
        NormaliseLineItems(tables, items, ctx)
    end
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
        if table[i].Total.Value and table[i].Description.Value then
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
end