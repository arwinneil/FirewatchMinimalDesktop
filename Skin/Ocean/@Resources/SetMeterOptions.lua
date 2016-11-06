function Update()
  local width, height = SKIN:ParseFormula(SKIN:GetVariable("Width")), SKIN:ParseFormula(SKIN:GetVariable("Height"))
  local nearestAxis, checkRotation = SKIN:GetMeasure("NearestAxis"):GetValue(), SKIN:GetMeasure("CheckRotation"):GetValue()
  
  if nearestAxis == 0 then
    SKIN:Bang("!SetOptionGroup", "Meter", "W", width)
    SKIN:Bang("!SetOptionGroup", "Meter", "H", height)
  else
    SKIN:Bang("!SetOptionGroup", "Meter", "W", height)
    SKIN:Bang("!SetOptionGroup", "Meter", "H", width)
  end
  
  if checkRotation == 0 then
    SKIN:Bang("!HideMeter", "BoundingBox")
  else
    if nearestAxis == 1 then
      SKIN:Bang("!SetOptionGroup", "Meter", "GraphOrientation", "Horizontal")
    end
    SKIN:Bang("!SetOptionGroup", "Meter", "AntiAlias", 1)
    SKIN:Bang("!SetOptionGroup", "Meter", "TransformationMatrix", SKIN:GetMeasure("Matrix"):GetStringValue())
    SKIN:Bang("!UpdateMeterGroup", "Meter")
    SKIN:Bang("!SetOptionGroup", "Meter", "TransformationMatrix", "")
  end
  
  SKIN:Bang("!SetOptionGroup", "Meter", "LeftMouseUpAction", "#OpenSettingsWindow#")
  SKIN:Bang("!UpdateMeterGroup", "Meter")
end