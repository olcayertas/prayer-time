# R8 rules for the release build. The Android/Compose/OkHttp/Glance libraries ship their own
# consumer rules; these cover this app's reflective surface.

# --- kotlinx.serialization -------------------------------------------------------------------
# Keep the @Serializable models in :domain and their generated $$serializer classes, so JSON
# decoding survives shrinking. (The serialization runtime's consumer rules cover most of this;
# these make the app's own models explicit.)
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault

-keepclassmembers class com.olcayertas.namazvakti.domain.** {
    *** Companion;
}
-keepclasseswithmembers class com.olcayertas.namazvakti.domain.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.olcayertas.namazvakti.domain.**$$serializer { *; }

# --- OkHttp / Okio ---------------------------------------------------------------------------
# OkHttp references optional TLS providers reflectively; they aren't on the classpath.
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
