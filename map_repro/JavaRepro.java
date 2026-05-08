import java.util.*;

public class JavaRepro {
    static void insertOne(Map<Integer,Integer> m, int k) {
        m.put(k, 100);
    }
    public static void main(String[] a) {
        Map<Integer,Integer> m = new HashMap<>(16);
        insertOne(m, 1);
        insertOne(m, 1);
        insertOne(m, 2);
        System.out.println("size=" + m.size() + " m[1]=" + m.get(1) + " m[2]=" + m.get(2));
    }
}
