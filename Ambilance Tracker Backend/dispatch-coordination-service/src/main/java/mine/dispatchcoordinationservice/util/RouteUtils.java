package mine.dispatchcoordinationservice.util;

import java.util.ArrayList;
import java.util.List;

public class RouteUtils {

    public static String mergePolylines(String polylineA, String polylineB) {
        List<double[]> pointsA = decodePolyline(polylineA);
        List<double[]> pointsB = decodePolyline(polylineB);

        if (!pointsA.isEmpty() && !pointsB.isEmpty()) {
            double[] lastA = pointsA.get(pointsA.size() - 1);
            double[] firstB = pointsB.get(0);
            if (Math.abs(lastA[0] - firstB[0]) < 1e-7 && Math.abs(lastA[1] - firstB[1]) < 1e-7) {
                pointsB.remove(0);
            }
        }

        List<double[]> merged = new ArrayList<>(pointsA);
        merged.addAll(pointsB);

        return encodePolyline(merged);
    }

    public static List<double[]> decodePolyline(String encoded) {
        List<double[]> poly = new ArrayList<>();
        int index = 0, len = encoded.length();
        int lat = 0, lng = 0;

        while (index < len) {
            int b, shift = 0, result = 0;
            do {
                b = encoded.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
            lat += dlat;

            shift = 0;
            result = 0;
            do {
                b = encoded.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
            lng += dlng;

            double latitude = lat / 1e5;
            double longitude = lng / 1e5;
            poly.add(new double[]{latitude, longitude});
        }
        return poly;
    }

    public static String encodePolyline(List<double[]> points) {
        StringBuilder encoded = new StringBuilder();
        int prevLat = 0, prevLng = 0;
        for (double[] p : points) {
            int lat = (int) Math.round(p[0] * 1e5);
            int lng = (int) Math.round(p[1] * 1e5);
            encoded.append(encodeSignedNumber(lat - prevLat));
            encoded.append(encodeSignedNumber(lng - prevLng));
            prevLat = lat;
            prevLng = lng;
        }
        return encoded.toString();
    }

    private static String encodeSignedNumber(int num) {
        int sgn_num = num << 1;
        if (num < 0) {
            sgn_num = ~sgn_num;
        }
        return encodeNumber(sgn_num);
    }

    private static String encodeNumber(int num) {
        StringBuilder sb = new StringBuilder();
        while (num >= 0x20) {
            int nextValue = (0x20 | (num & 0x1f)) + 63;
            sb.append((char)(nextValue));
            num >>= 5;
        }
        num += 63;
        sb.append((char)(num));
        return sb.toString();
    }

    public static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371e3;
        double phi1 = Math.toRadians(lat1);
        double phi2 = Math.toRadians(lat2);
        double dPhi = Math.toRadians(lat2 - lat1);
        double dLambda = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dPhi / 2) * Math.sin(dPhi / 2)
                + Math.cos(phi1) * Math.cos(phi2)
                * Math.sin(dLambda / 2) * Math.sin(dLambda / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    public static double lerp(double start, double end, double alpha) {
        return start + alpha * (end - start);
    }
}
