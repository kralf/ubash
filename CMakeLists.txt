cmake_minimum_required(VERSION 2.6)

include(ReMake)

remake_project(
  uBash
  VERSION 0.1
  RELEASE beta
  SUMMARY "A collection of useful bash scripts spanning a growing area of applications."
  AUTHOR "Ralf Kaestner"
  CONTACT "ralf.kaestner@gmail.com"
  HOME "http://aslforge.ethz.ch/projects/ubash"
  LICENSE "GNU Lesser General Public License (LGPL)"
  INSTALL /usr
)

remake_doc(
  man INSTALL share
  ps
  html
)

remake_pack_deb(ARCH all bash)
remake_pack_deb(ARCH all COMPONENT doc)
