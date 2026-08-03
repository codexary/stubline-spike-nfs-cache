package com.elsworne.stubline.spike.nfscache;

/** Entry point that directs users to the kernel-backed NFS experiment. */
public final class NfsCacheSpike {
  private NfsCacheSpike() {}

  public static void main(String[] args) {
    System.out.println("Run scripts/observe.sh on a Linux Docker host with NFS kernel support.");
  }
}
