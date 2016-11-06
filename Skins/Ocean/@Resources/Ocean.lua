-- Ocean v2.0
-- LICENSE: Creative Commons Attribution-Non-Commercial-Share Alike 3.0

function Initialize()
  measure, measureBuffer, meter = {}, {}, {}
  interpolateSpan = SELF:GetNumberOption("InterpolateSpan")
  mu = 1 / interpolateSpan
  spectrumSize = SELF:GetNumberOption("SpectrumSize")
  
  measureCallbackName = SELF:GetOption("MeasureCallbackName")
  updateBang = "[!UpdateMeasure " .. measureCallbackName .. "][!UpdateMeterGroup " .. SELF:GetOption("MeterGroupName") .. "]"
  
  meterIter, lowerLimit, upperLimit = 1, SELF:GetNumberOption("LowerLimit") + 1, SELF:GetNumberOption("UpperLimit") + 1
  for i = lowerLimit, upperLimit do
    meter[i], measure[i] = {}, SKIN:GetMeasure(SELF:GetOption("MeasureBaseName") .. i-1) 
    for j = 1, interpolateSpan do
      meterIter, meter[i][j] = meterIter + 1, SKIN:GetMeter(SELF:GetOption("MeterBaseName") .. meterIter)
    end
  end
end

-- http://paulbourke.net/miscellaneous/interpolation/
local function CubicInterpolate(y0,y1,y2,y3,mu)
   local mu2,a0 = mu*mu, y3-y2-y0+y1
   local a1 = y0-y1-a0
   return (a0*mu*mu2+a1*mu2+(y2-y0)*mu+y1)
end
  
function Update()
  for i = lowerLimit, upperLimit do measureBuffer[i] = measure[i]:GetValue() end
  
  local spectrumSize = spectrumSize
  for i = lowerLimit, upperLimit-1 do
    local localMu, meter = 0, meter[i]
    local y0, y3 = measureBuffer[i-1 < lowerLimit and lowerLimit or i-1], measureBuffer[i+2 > upperLimit and upperLimit or i+2]
	local y1, y2 = measureBuffer[i], measureBuffer[i+1]
    for j = 1, interpolateSpan do
      localMu = localMu + mu
	  
      SKIN:Bang("!CommandMeasure", measureCallbackName, "x=" .. CubicInterpolate(y0,y1,y2,y3,localMu))
	  SKIN:Bang(updateBang)
	  
	  spectrumSize = spectrumSize - 1
	  if spectrumSize == 0 then
	    return
	  end
    end
  end
end