cmake_minimum_required(VERSION 2.6)

include(ReMake)

remake_project(
  uBash
  0.1
  beta
  "A collection of useful bash scripts spanning a growing area of applications."
  "Ralf Kaestner"
  "ralf.kaestner@gmail.com"
  "http://aslforge.ethz.ch/projects/ubash"
  "GNU Lesser General Public License (LGPL)"
  INSTALL /usr
)

remake_doc(
  man INSTALL share
  ps
  html
)

remake_pack_deb(ARCH all bash)
remake_pack_deb(ARCH all COMPONENT doc)
