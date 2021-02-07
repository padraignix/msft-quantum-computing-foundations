namespace MyGroversJob {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Characterization;

    //operation SampleManyRandomBits(nQubits : Int, idxMarked : Int, nBits : Int) : Result[] {
    //    mutable results = EmptyArray<Result>();
    //    for (_ in 1..nBits) {
    //        set results += GroversTest(nQubits, idxMarked);
    //    }
    //    return results;
    //    }

    @EntryPoint()
    operation SampleManyRandomBits(nQubits : Int, idxMarked : Int, nBits : Int) : Result[][] {
        return DrawMany(GroversTest, nBits, (nQubits, idxMarked));
    }

    //https://quantumcomputing.stackexchange.com/questions/15686/q-simulation-behavior
    //@EntryPoint()
    //operation EstimateHeadsProbability(nShots : Int) : Double {
    //    return EstimateFrequency(ApplyToEach(H, _), Measure([PauliZ], _), 1, nShots);
    //}

    //operation EstimateHeadsProbability(nQubits : Int, idxMarked : Int, nShots : Int) : Double {
    //    return EstimateFrequency(GroversTest(nQubits, idxMarked), 1, nShots);
    //}

    operation GroversTest(nQubits : Int, idxMarked : Int) : Result[] {
        // Define the oracle
        let markingOracle = MarkingNumber(idxMarked, _, _);
        let phaseOracle = ApplyMarkingOracleAsPhaseOracle(markingOracle, _);
        // Set the number of iterations of the algorithm
        let nIterations = NIterations(nQubits);

        // Initialize the register to run the algorithm
        using (qubits = Qubit[nQubits]){
                // Run the algorithm
                RunGroversSearch(qubits, phaseOracle, nIterations);
                // Obtain the results and reset the register
                return ForEach(MResetZ, qubits);
        }
    }

    function NIterations(nQubits : Int) : Int {
        let nItems = 1 <<< nQubits;
        let angle = ArcSin(1. / Sqrt(IntAsDouble(nItems)));
        let nIterations = Round(0.25 * PI() / angle - 0.5);
        return nIterations;
    }

    operation MarkingNumber (
        idxMarked : Int,
        inputQubits : Qubit [],
        target : Qubit
    ) : Unit is Adj+Ctl {
        (ControlledOnInt(idxMarked, X))(inputQubits, target);
    }

    operation ApplyMarkingOracleAsPhaseOracle(
        markingOracle : ((Qubit[], Qubit) => Unit is Adj), 
        register : Qubit[]
    ) : Unit is Adj {
        using (target = Qubit()) {
            within {
                X(target);
                H(target);
            } apply {
                markingOracle(register, target);
            }
        }
    }

    operation RunGroversSearch(register : Qubit[], phaseOracle : ((Qubit[]) => Unit is Adj), iterations : Int) : Unit {
        ApplyToEachCA(H, register);
        for (_ in 1 .. iterations) {
            phaseOracle(register);
            ReflectAboutUniform(register);
        }
    }

    operation ReflectAboutUniform(inputQubits : Qubit[]) : Unit {
        within {
            ApplyToEachCA(H, inputQubits);
            ApplyToEachCA(X, inputQubits);
        } apply {
            Controlled Z(Most(inputQubits), Tail(inputQubits));
        }
    }
    
}