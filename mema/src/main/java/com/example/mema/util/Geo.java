package com.example.mema.util;

public final class Geo {

    private Geo() {}

    /** Distance à vol d'oiseau entre deux points, en kilomètres (formule de Haversine). */
    public static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
        final double rayonTerre = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * rayonTerre * Math.asin(Math.sqrt(a));
    }
}