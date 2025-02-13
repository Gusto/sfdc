public class RandomNumberGenerator{
    public static Integer generateRandomNumber(Integer intMin, Integer intMax){
        return Integer.valueOf(Math.floor(Math.random() * ((intMax - intMin) + 1) + intMin));
    }
}