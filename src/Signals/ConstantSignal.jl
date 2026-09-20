"""
    ConstantSignal(; name, u0 = 0.0)

Reusable scalar signal source. The numeric center value is a tunable parameter,
so control studies can vary it without embedding the signal definition inside a
physical component.
"""
@component function ConstantSignal(; name, u0 = 0.0)
    @named y = SignalPlug()
    @parameters u_const = u0 [tunable = true, description = "Constant signal value"]

    eqs = [
        y.u ~ u_const
    ]

    return System(
        eqs,
        t,
        [],
        [u_const];
        systems = [y],
        name = name,
    )
end
