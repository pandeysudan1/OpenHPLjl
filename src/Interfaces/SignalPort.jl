"""
    SignalSocket

Causal scalar signal input connector.

The signal direction is explicit: a component that receives a control,
measurement or disturbance signal owns a `SignalSocket`.
"""
@connector function SignalSocket(; name)
    vars = @variables u(t) [input = true, guess = 0.0, description = "Input signal"]
    return System(Equation[], t, vars, []; name = name)
end

"""
    SignalPlug

Causal scalar signal output connector.

A source, sensor or controller that provides a scalar signal owns a
`SignalPlug`.
"""
@connector function SignalPlug(; name)
    vars = @variables u(t) [output = true, guess = 0.0, description = "Output signal"]
    return System(Equation[], t, vars, []; name = name)
end
